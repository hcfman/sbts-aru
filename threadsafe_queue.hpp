// Copyright (c) 2023 Kim Hendrikse

#include <deque>
#include <mutex>
#include <condition_variable>

template <typename T>
class ThreadsafeQueue {
public:
    ThreadsafeQueue() : q(), m(), cv() {}

    void enqueue(T t) {
        std::lock_guard<std::mutex> lock(m);
        q.push_back(t);
        cv.notify_one();
    }

    T dequeue() {
        std::unique_lock<std::mutex> lock(m);
        while (q.empty()) {
            cv.wait(lock);
        }
        T val = q.front();
        q.pop_front();
        return val;
    }

    bool empty() {
        std::lock_guard<std::mutex> lock(m);
        return q.empty();
    }

private:
    std::deque<T> q;
    std::mutex m;
    std::condition_variable cv;
};
