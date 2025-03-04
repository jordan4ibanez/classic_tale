module utility.uuid;

static final const class UUID {
static:
private:
    ulong id = 0;

public:

    ulong get() {
        const ulong result = id;
        id++;
        return id;
    }

}
