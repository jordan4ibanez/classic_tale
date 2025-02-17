default:
	@dub run

fast:
	@dub run --version=release

debug:
	DFLAGS="-g -gc -d-debug" dub build  && gdb -q -ex run ./classic_fable

clean:
	@dub clean