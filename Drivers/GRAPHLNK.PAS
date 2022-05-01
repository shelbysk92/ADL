{$I COMPILER.TXT}
unit GraphLnk;

interface

uses
  Graph;

procedure ATTDriverProc;
procedure CgaDriverProc;
procedure EgaVgaDriverProc;
procedure HercDriverProc;
procedure PC3270DriverProc;
procedure SVga256DriverProc;

implementation

{procedure SVga256DriverProc; external;
{$L SVGA256.OBJ }

{procedure ATTDriverProc; external;
{$L ATT.OBJ }

{procedure CgaDriverProc; external;
{$L CGA.OBJ }

{procedure EgaVgaDriverProc; external;
{$L EGAVGA.OBJ }

{procedure HercDriverProc; external;
{$L HERC.OBJ }

{procedure PC3270DriverProc; external;
{$L PC3270.OBJ }
}

end.

