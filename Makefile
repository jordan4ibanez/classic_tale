default:
	@dub run

fast:
	@dub run --build=release

debug:
	DFLAGS="-g -gc -d-debug" dub build  && gdb -q -ex run ./classic_fable

clean:
	@dub clean