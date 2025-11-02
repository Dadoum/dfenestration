module dfenestration.containers.queuelist;

import core.sync.mutex;

import std.range;

/**
 * I am not good at coming up with names.
 * This List is a data structure useful to keep animations sorted by their end time
 * and allows easy insertions, browsing and removals.
 */
struct QueueList(T) {
    struct Node {
        T* value;
        Node* prev;
        Node* next;
    }

    alias forward = Node.next;
    alias backward = Node.prev;
    struct Range(alias direction = forward) {
        Node* value;

        Node* front() => value;
        Node* popFront() => __traits(child, *value, direction);
        bool empty() => value == null;
    }

    Node* start = null;
    Node* end = null;
    Mutex mutex;

    @disable this();

    this(Node* start, Node* end) {
        this.start = start;
        this.end = end;
        this.mutex = new Mutex();
    }

    /**
     * Insert before the first element verifying b(element).
     * When there is none, just inserts.
     *
     * In our use case, it can insert the animation at the right time.
     */
    Node* insertWhen(bool delegate(ref T) b, T* element) {
        mutex.lock();
        scope(exit) mutex.unlock();
        // We browse the list starting by the end as it is more likely there.
        if (end is null) {
            auto node = new Node(element, null, null);
            start = node;
            end = node;
            return node;
        }
        if (b(*end.value)) {
            auto node = new Node(element, start, null);
            end.next = node;
            end = node;
            return node;
        }
        {
            Node* node = end;
            while (node.prev) {
                if (b(*node.prev.value)) {
                    Node *elem = new Node(element, node.prev, node);
                    node.prev.next = elem;
                    node.prev = elem;
                    return node;
                }
            }
        }
        Node *node = new Node(element, null);
        start.prev = node;
        start = node;
        return node;
    }

    /**
     * Executes a handler on every node, and remove those for which shouldRemove(element).
     *
     * This allows us to step every animations and remove those which are finished at the same time.
     */
    void removeExecute(bool delegate(ref T elem) shouldRemove) {
        mutex.lock();
        scope(exit) mutex.unlock();
        while (start && shouldRemove(*start.value)) {
            start = start.next;
        }
        if (start is null) {
            end = null;
            return;
        }
        auto previous = start;
        while (previous.next) {
            if (shouldRemove(*previous.next.value)) {
                previous.next = previous.next.next;
                if (previous.next) {
                    previous.next.prev = previous;
                } else {
                    end = previous;
                    break;
                }
            }
            previous = previous.next;
        }
    }

    void remove(Node* node) {
        mutex.lock();
        scope(exit) mutex.unlock();
        if (node.prev == null) {
            start = node.next;
        }
        if (node.next == null) {
            end = node.prev;
        }
        if (node.prev && node.next) {
            node.prev.next = node.next;
            node.next.prev = node.prev;
        }
    }

    bool empty() => start is null;
}
