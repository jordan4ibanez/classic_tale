module utility.uuid;

static final const class UUID {
static:
private:
    ulong id = 1;

public:

    ulong get() {
        const ulong result = id;
        id++;
        return id;
    }
}
