module dfenestration.animation;

public import std.datetime;

import dfenestration.containers.queuelist;
import dfenestration.widgets.window;

struct Animation {
    MonoTime animationEndTime;
    Duration duration;
    void delegate(float progress) update;
    bool isCosmetic;

    bool completed = false;

    this(Duration duration, void delegate(float progress) update, bool isCosmetic = false) {
        animationEndTime = MonoTime.currTime + duration;
        this.duration = duration;
        this.update = update;
        this.isCosmetic = isCosmetic;
    }
}

struct AnimationCancellationToken {
    QueueList!Animation.Node* node = null;

    bool valid() {
        return node !is null;
    }

    void cancel(Window window) {
        if (!node.value.completed) {
            node.value.completed = true;
            window.animations.remove(node);
            node = null;
        }
    }
}

float lerp(float start, float end, float progress) {
    return start * (1.0 - progress) + (end * progress);
}
