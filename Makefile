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

# Source directories
SRCDIR = src

# Source files
SOURCES = $(SRCDIR)/battle_royale.asm
RESOURCES = $(SRCDIR)/rsrc.rc

# Object and Resource files
OBJECTS = $(SOURCES:.asm=.obj)
RESOBJ = $(RESOURCES:.rc=.res)

# Executable output
EXECUTABLE = .\bin\battle_royale.exe

# Default target
all: $(EXECUTABLE)

# Rule to compile assembly files
$(SRCDIR)/%.obj: $(SRCDIR)/%.asm
	$(ASM) $(ASMFLAGS) /Fo$@ $<

# Rule to compile resource files
$(SRCDIR)/%.res: $(SRCDIR)/%.rc
	$(RC) $(RCFLAGS) $@ $<

# Rule to create the executable
$(EXECUTABLE): $(OBJECTS) $(RESOBJ)
	@if not exist ".\bin" mkdir ".\bin"
	$(LINKER) $(LINKFLAGS) $(OBJECTS) $(RESOBJ) /OUT:$(EXECUTABLE)

# Clean target include object files, resource files, and executable
clean:
	del /Q /F src\*.obj
	del /Q /F src\*.res
	del /Q /F bin\*.exe

# Phony targets
.PHONY: all clean
