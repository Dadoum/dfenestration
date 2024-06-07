module dfenestration.linkedlist;

struct LinkedList(T) {
    struct Node {
        Node* next;
        T object;
    }

    Node* head = null;

    void insertAt(size_t index, T object) {
        Node** node = &head;
        foreach (idx; 0..index) {
            assert(*node);
            node = &((*node).next);
        }
        *node = new Node(*node ? (*node).next : null, object);
    }

    void insertAfter(bool delegate(T) condition, T object) {
        Node** node = &head;
        while (*node && condition((*node).object)) {
            assert(*node);
            node = &((*node).next);
        }
        *node = new Node(*node ? *node : null, object);

        Node* node2 = head;
        while (node2) {
            import std.logger;
            info(*node2);
            node2 = node2.next;
        }
    }

    void removeFront() {
        head = head.next;
    }
}
