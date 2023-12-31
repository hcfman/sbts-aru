// Copyright (c) 2023 Kim Hendrikse

#include <chrono>
#include <jack/jack.h>

class BufferChunk {
public:
    std::vector<jack_default_audio_sample_t> audioFrames;
    jack_nframes_t nframes;
    long long latency;
    decltype(std::chrono::system_clock::now()) arrivalTime;
    jack_nframes_t jackLastFrameTime;
};
