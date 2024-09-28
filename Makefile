rwildcard=$(foreach d,$(wildcard $(1:=/*)),$(call rwildcard,$d,$2) $(filter $(subst *,%,$2),$d))
SOURCES=$(call rwildcard,src,*.asm)
DEST=hrun

$(DEST): $(SOURCES)
	sjasmplus src/main.asm -DV=01

clean:
	rm $(DEST)
