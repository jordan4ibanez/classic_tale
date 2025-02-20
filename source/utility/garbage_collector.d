module utility.garbage_collector;

import core.memory;

static final const class GarbageCollector {
static:
private:

    immutable ulong averager = 200;
    double[averager] gcCollection = 0;
    ulong index = 0;

public:

    // I keep this here for testing.
    // GC.disable();

    // This averages out the GC heap info in megabytes so you can actually read it.
    double getHeapInfo() {
        gcCollection[index] = cast(double) GC.stats().usedSize / 1_000_000.0;

        double total = 0;
        foreach (size; gcCollection) {
            total += size;
        }
        total /= averager;

        index++;
        if (index >= averager) {
            index = 0;
        }

        return total;
    }

}
