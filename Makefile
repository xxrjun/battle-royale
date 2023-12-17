# Makefile for the Battle Royale project

# Assembler, resource compiler, and linker programs
ASM = ml
RC = rc
LINKER = link

# Assembler flags (for Microsoft Macro Assembler)
ASMFLAGS = /c /coff /Cp

# Resource Compiler flags
RCFLAGS = /fo

# Linker flags
LINKFLAGS = /SUBSYSTEM:CONSOLE /DEBUG

# Source and binary directories
SRCDIR = src
BINDIR = bin

# Source files
SOURCES = $(SRCDIR)/battle_royale.asm
RESOURCES = $(SRCDIR)/rsrc.rc

# Object and Resource files in bin directory
OBJECTS = $(patsubst $(SRCDIR)/%.asm,$(BINDIR)/%.obj,$(SOURCES))
RESOBJ = $(patsubst $(SRCDIR)/%.rc,$(BINDIR)/%.res,$(RESOURCES))

# Executable output
EXECUTABLE = $(BINDIR)/battle_royale.exe

# Default target
all: $(EXECUTABLE)

# Rule to compile assembly files
$(BINDIR)/%.obj: $(SRCDIR)/%.asm
	@if not exist "$(BINDIR)" mkdir "$(BINDIR)"
	$(ASM) $(ASMFLAGS) /Fo$@ $<

# Rule to compile resource files
$(BINDIR)/%.res: $(SRCDIR)/%.rc
	@if not exist "$(BINDIR)" mkdir "$(BINDIR)"
	$(RC) $(RCFLAGS) $@ $<

# Rule to create the executable
$(EXECUTABLE): $(OBJECTS) $(RESOBJ)
	$(LINKER) $(LINKFLAGS) $(OBJECTS) $(RESOBJ) /OUT:$(EXECUTABLE)

# Clean target include object files, resource files, and executable
clean:
	del /Q /F $(BINDIR)\*.obj
	del /Q /F $(BINDIR)\*.res
	del /Q /F $(BINDIR)\*.exe
	del /Q /F $(BINDIR)\*.pdb
	del /Q /F $(BINDIR)\*.ilk

# Phony targets
.PHONY: all clean
