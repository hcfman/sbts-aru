#include <fstream>
#include <iostream>
#include <jack/jack.h>
#include <sndfile.h>
#include <chrono>

#include <iomanip>
#include <sstream>
#include <unistd.h>
#include <csignal>

#include <atomic>
#include <queue>
#include <mutex>
#include <condition_variable>
#include <thread>
#include <utility>

#include "threadsafe_queue.hpp"
#include "buffer_chunk.hpp"

#if __cplusplus >= 201703L && __has_include(<filesystem>)
#  include <filesystem>
#elif __has_include(<experimental/filesystem>)

#  include <experimental/filesystem>

#endif

std::queue<BufferChunk> data_queue;
std::mutex queue_mutex;
std::condition_variable data_condition;
std::atomic<bool> writer_running(true);
std::atomic<bool> closingCurrentFile(false);
std::atomic<bool> isFileOpen(false);
std::atomic<bool> isLogJackTime(false);

#if __cplusplus >= 201703L && __has_include(<filesystem>)
#  include <filesystem>
namespace fs = std::filesystem;
#elif __has_include(<experimental/filesystem>)

#  include <experimental/filesystem>

namespace fs = std::experimental::filesystem;
#endif

jack_client_t *client;
jack_port_t *input_port;

std::string name, clientName, inputSource, portName;
std::string currentFileName;
std::string calculatedTimestamp;
std::ofstream timestampFile;


std::mutex timestamp_mutex;
int minutes = 20;

// Queue of samples
ThreadsafeQueue<BufferChunk> sampleQueue;

SNDFILE *outfile;
SF_INFO sfinfo;

int outputBitrate;
int chunkDuration;
int framesLeft;

// Have we been called back for the first frame of the file yet ?
long long bufferCounter = 0;

void setCalculatedTimestamp(std::string newTimestamp) {
    std::lock_guard<std::mutex> lock(timestamp_mutex);
    calculatedTimestamp = std::move(newTimestamp);
}

std::string getCalculatedTimestamp() {
    std::lock_guard<std::mutex> lock(timestamp_mutex);
    return calculatedTimestamp;
}

void setRecordTime() {
    chunkDuration = minutes * 60;
    framesLeft = chunkDuration * outputBitrate;
}

std::string getDateTimestampFromTime(std::chrono::time_point<std::chrono::system_clock> theTime) {
    auto us = std::chrono::duration_cast<std::chrono::microseconds>(theTime.time_since_epoch()) % 1000000;

    std::time_t t = std::chrono::system_clock::to_time_t(theTime);
    std::tm *time = std::localtime(&t);

    std::stringstream ss;
    ss << std::put_time(time, "%Y-%m-%d_%H-%M-%S") << "." << std::setfill('0') << std::setw(6) << us.count();
    std::string timeString = ss.str();
    return timeString;
}

std::string getTimestampFromTime(std::chrono::time_point<std::chrono::system_clock> theTime) {
    auto us = std::chrono::duration_cast<std::chrono::microseconds>(theTime.time_since_epoch()) % 1000000;

    std::time_t t = std::chrono::system_clock::to_time_t(theTime);
    std::tm *time = std::localtime(&t);

    std::stringstream ss;
    ss << std::put_time(time, "%H-%M-%S") << "." << std::setfill('0') << std::setw(6) << us.count();
    std::string timeString = ss.str();
    return timeString;
}

std::string getDirectoryStructure() {
    auto now = std::chrono::system_clock::now();

    std::time_t t = std::chrono::system_clock::to_time_t(now);
    std::tm *time = std::localtime(&t);

    std::stringstream ss;
    ss << std::put_time(time, "%Y/%Y-%m/%Y-%m-%d");
    return ss.str();
}

std::chrono::time_point<std::chrono::system_clock> calcStarttime(jack_nframes_t nframes, long long latency,
                                                                 std::chrono::time_point<std::chrono::system_clock> arrivalTime) {
    long long buffer_time_in_microseconds = (static_cast<double>(nframes + latency)) * 1e6 / outputBitrate;
    auto startTime = arrivalTime - std::chrono::microseconds(buffer_time_in_microseconds);
    return startTime;
}

void openNewFile(std::chrono::time_point<std::chrono::system_clock> startTime) {
#if __cplusplus >= 201703L && __has_include(<filesystem>)
    std::filesystem::path dir = getDirectoryStructure();
    std::filesystem::create_directories(dir);
#elif __has_include(<experimental/filesystem>)
    std::experimental::filesystem::path dir = getDirectoryStructure();
    std::experimental::filesystem::create_directories(dir);
#endif

    std::string nowTimestamp = getDateTimestampFromTime(startTime);
    std::string filename = nowTimestamp + ".flac";

#if __cplusplus >= 201703L && __has_include(<filesystem>)
    std::filesystem::path filePath = dir / filename;
    std::filesystem::path timestampTrackingFilePath = dir / (nowTimestamp + ".tracking");
#elif __has_include(<experimental/filesystem>)
    std::experimental::filesystem::path filePath = dir / filename;
    std::experimental::filesystem::path timestampTrackingFilePath = dir / (nowTimestamp + ".tracking");
#endif

    currentFileName = filePath;
    std::cout << "Creating: " << currentFileName << std::endl;

    sfinfo.samplerate = outputBitrate;
    sfinfo.channels = 1;
    sfinfo.format = SF_FORMAT_FLAC | SF_FORMAT_PCM_16;

    if (!(outfile = sf_open(filePath.c_str(), SFM_WRITE, &sfinfo))) {
        std::cerr << "Cannot open file " << filePath << std::endl;
        exit(1);
    }

    // std::cout << "Opening tracking file " << timestampTrackingFilePath << std::endl;
    timestampFile.open(timestampTrackingFilePath.c_str());
    if (!timestampFile) {
        std::cerr << "Cannot open tracking file " << filePath << std::endl;
        exit(1);
    }

    isFileOpen = true;
}

std::string replaceSuffix(std::string fromString, const std::string &fromSuffix, const std::string &toSuffix) {
    if (fromString.size() > fromSuffix.size() &&
        fromString.substr(fromString.size() - fromSuffix.size()) == fromSuffix) {
        fromString.replace(fromString.end() - fromSuffix.size(), fromString.end(), toSuffix);
    }

    return fromString;
}

void
finish_file(jack_nframes_t nframes, long long latency, std::chrono::time_point<std::chrono::system_clock> arrivalTime) {
    sf_close(outfile);
    timestampFile.close();

    // Calculate the frame arrival time including latency
    long long buffer_time_in_microseconds = (static_cast<double>(latency)) * 1e6 / outputBitrate;
    auto endTime = arrivalTime - std::chrono::microseconds(buffer_time_in_microseconds);

    std::string oldName = currentFileName;

    // Find the last path separator
    std::size_t pathSeparatorPos = oldName.find_last_of("/\\");

    // Get the basename (filename with extension)
    std::string basenameWithExt = oldName.substr((pathSeparatorPos == std::string::npos) ? 0 : pathSeparatorPos + 1);

    // Find the ".flac" extension
    std::size_t extPos = basenameWithExt.rfind(".flac");

    // Check if the extension was found
    std::string startTimeString;
    if (extPos != std::string::npos) {
        startTimeString = basenameWithExt.substr(0, extPos);
    }

    // Calculate a new name for the completed file
#if __cplusplus >= 201703L && __has_include(<filesystem>)
    std::filesystem::path p(oldName);
    std::filesystem::path dir = p.parent_path();

    std::filesystem::path newName = dir / (startTimeString + "--" + name + "--" + getDateTimestampFromTime(endTime) + ".flac");
#elif __has_include(<experimental/filesystem>)
    std::experimental::filesystem::path p(oldName);
    std::experimental::filesystem::path dir = p.parent_path();

    std::experimental::filesystem::path newName =
            dir / (startTimeString + "--" + name + "--" + getDateTimestampFromTime(endTime) + ".flac");
#endif

    std::rename(oldName.c_str(), newName.c_str());
    std::cout << "Closing to: " << newName << std::endl << std::endl;
    std::rename(replaceSuffix(oldName, ".flac", ".tracking").c_str(),
                replaceSuffix(newName, ".flac", ".tracking").c_str());

    isFileOpen = false;
    bufferCounter = 0;
}

extern "C" void handleInt(int sig) { // must be declared extern "C" to match type required by std::signal
    std::cout << "Signal received: " << sig << std::endl;

    writer_running = false;
    data_condition.notify_all();  // Notify the writer thread to finish up

    printf("Aborting...");
    std::cout << "File name " << currentFileName << std::endl;
}


extern "C" void handleHup(int sig) { // must be declared extern "C" to match type required by std::signal
    std::cout << "HUP signal received: " << sig << std::endl;

    closingCurrentFile = true;
    data_condition.notify_all();  // Notify the writer thread to finish up

    printf("Closing current file...");
    std::cout << "File name " << currentFileName << std::endl;
}

void writer_thread_fn() {
    BufferChunk bufferChunk;
    std::vector<float> data;

    while (true) {
        std::unique_lock<std::mutex> lock(queue_mutex);
        data_condition.wait(lock, [] { return !sampleQueue.empty() || !writer_running; });

        bufferChunk = sampleQueue.dequeue();

        data = bufferChunk.audioFrames;

        auto startTime = calcStarttime(bufferChunk.nframes, bufferChunk.latency, bufferChunk.arrivalTime);

        if (!isFileOpen) {
            openNewFile(startTime);
        }

        if (!data.empty()) {
            // Write the buffer of frames to the audio file
            sf_writef_float(outfile, data.data(), data.size());

            // Update the tracking file
            if (isLogJackTime) {
                timestampFile << bufferCounter << " " << getTimestampFromTime(startTime) << " "
                              << bufferChunk.jackLastFrameTime << std::endl;
            } else {
                timestampFile << bufferCounter << " " << getTimestampFromTime(startTime) << std::endl;
            }
            bufferCounter++;

            framesLeft -= data.size();

            if (!writer_running) {
                framesLeft = 0;
            }

            if (closingCurrentFile) {
                framesLeft = 0;
                closingCurrentFile = false;
            }

            if (framesLeft <= 0) {
                finish_file(bufferChunk.nframes, bufferChunk.latency, bufferChunk.arrivalTime);

                framesLeft = chunkDuration * outputBitrate;

                if (!writer_running) {
                    printf("Quiting writer thread\n");
                    return;
                }
            }

        }
    }
}

int process(jack_nframes_t nframes, void *arg) {
    // Directly calculate kimDiff without intermediate storage
    jack_nframes_t jackLastFrameTime = jack_last_frame_time(client);
    auto adjustment = static_cast<int64_t>(jack_get_time() -
                                           static_cast<int64_t>(jack_frames_to_time(client, jackLastFrameTime)));

    // Get the latency
    jack_latency_range_t latencyRange;
    jack_port_get_latency_range(input_port, JackCaptureLatency, &latencyRange);

    // Vector from the  buffer
    auto *in = (jack_default_audio_sample_t *) jack_port_get_buffer(input_port, nframes);

    // Enqueue samples instead of writing to file
    BufferChunk chunk;
    chunk.audioFrames = std::vector<jack_default_audio_sample_t>(in, in + nframes);
    chunk.nframes = nframes;
    chunk.latency = latencyRange.min;
    chunk.arrivalTime = std::chrono::system_clock::now() - std::chrono::microseconds(adjustment);
    chunk.jackLastFrameTime = jackLastFrameTime;
    sampleQueue.enqueue(chunk);

    data_condition.notify_all();  // Notify the writer thread to finish up

    return 0;
}

void usage(char *argv[]) {
    std::cerr << "Usage: " << argv[0]
              << " -n <Name handleInt for the source> -c <Name of this client program> -p <name of the inputport> -s <jackd source> -t <time in minutes> -b <input bitrate> [-j]\n";
}

int main(int argc, char *argv[]) {
    const char **ports;

    int c;
    while ((c = getopt(argc, argv, "n:c:s:p:t:b:j")) != -1) {
        switch (c) {
            case 'n':
                name = optarg;
                break;
            case 'c':
                clientName = optarg;
                break;
            case 's':
                inputSource = optarg;
                break;
            case 'p':
                portName = optarg;
                break;
            case 't':
                try {
                    minutes = std::stoi(optarg);
                } catch (const std::invalid_argument &e) {
                    std::cerr << "Value of time is invalid, no conversion could be performed\n";
                    exit(1);
                } catch (const std::out_of_range &e) {
                    std::cerr << "Time value is out of range for a integer\n";
                    exit(1);
                }

                break;
            case 'b':
                try {
                    outputBitrate = std::stoi(optarg);
                } catch (const std::invalid_argument &e) {
                    std::cerr << "Value of input bitrate is invalid, no conversion could be performed\n";
                    exit(1);
                } catch (const std::out_of_range &e) {
                    std::cerr << "Input bitrate value is out of range for a integer\n";
                    exit(1);
                }
                break;
            case 'j':
                isLogJackTime = true;
                break;
            case '?':
                std::cerr << "Unknown option: -" << optopt << '\n';
                return 1;
            default:
                usage(argv);
                return 1;
        }
    }

    if (name.empty() || clientName.empty() || inputSource.empty()) {
        usage(argv);
        return 1;
    }

    setRecordTime();

    jack_status_t status;

    // Start the writer thread
    std::thread writer_thread(writer_thread_fn);

    if ((client = jack_client_open(clientName.c_str(), JackNullOption, &status)) == nullptr) {
        std::cerr << "jack server not running?" << std::endl;
        unlink(currentFileName.c_str());
        return 1;
    }

    if (client == nullptr) {
        std::cerr << "jack server not running?" << std::endl;
        unlink(currentFileName.c_str());
        return 1;
    }

    jack_set_process_callback(client, process, nullptr);

    input_port = jack_port_register(client, portName.c_str(), JACK_DEFAULT_AUDIO_TYPE, JackPortIsInput, 0);

    if (jack_activate(client)) {
        std::cerr << "cannot activate client";
        unlink(currentFileName.c_str());
        return 1;
    }

    ports = jack_get_ports(client, inputSource.c_str(), nullptr, JackPortIsOutput);

    if (ports == nullptr) {
        std::cerr << "no available ports" << std::endl;
        unlink(currentFileName.c_str());
        return 1;
    }

    if (jack_connect(client, ports[0], jack_port_name(input_port))) {
        unlink(currentFileName.c_str());
        std::cerr << "cannot connect input ports" << std::endl;
        return 1;
    }

    std::signal(SIGTERM, handleInt);
    std::signal(SIGINT, handleInt);
    std::signal(SIGHUP, handleHup);

    // Loop forever and wait for the writer loop to terminate
    while (writer_running) {
        sleep(-1);
    }

    writer_thread.join();

    jack_port_unregister(client, input_port);
    jack_client_close(client);
    return 0;
}
