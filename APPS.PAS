{$IFDEF debug}
  {$A+,B-,D+,F+,G+,I+,L+,N+,P+,Q+,R+,S+,V+,X+,Y+}
{$ELSE}
  {$A+,B-,D-,F+,G+,I+,L-,N+,P+,Q-,R-,S-,V+,X+,Y-}
{$ENDIF}
unit Apps;

interface

uses
  Crt,
  Objects,
  MemDrv,
  KeyDrv,
  Dos,
  Utils,
  MouseDrv;

type
  PApplication = ^TApplication;
  TApplication = object(TObject)
  private
  public
    Closed: boolean;
    InterfaceMemory: longint;
    constructor Create(newId: string; interfaceMem: longint);
    procedure Init; virtual;
    procedure Run; virtual;
    procedure Close; virtual;
    procedure MainLoop; virtual;
    procedure ProcessEvents; virtual;
    destructor Done; virtual;
  end;

implementation

var
  Keyboard: TKeyboardDriver;

constructor TApplication.Create(newId: string; interfaceMem: longint);
begin
  InterfaceMemory := interfaceMem;
  Id := newId;
  Init;
end;

procedure TApplication.Init;
var
  {$IFDEF debug}
    filename: string;
    debugFile: File;
    xmsHandle: word;
    xmsControl: pointer;
  {$ENDIF}
begin
  TObject.Init;
  TypeName := 'TApplication';
  ClrScr;
  {$IFDEF debug}
    { Deallocate the last used XMS handle if the program abnormally terminated}
    filename := 'XmsDebug.bin';
    if FileExists(FileName) then
    begin
      Assign(debugFile, filename);
      Reset(debugFile, 1);
      BlockRead(debugFile, xmsHandle, SizeOf(xmsHandle));
      System.Close(debugFile);
      asm
        push es
        mov  ax, 4310h
        int  2Fh
        mov  word ptr [xmsControl], bx
        mov  word ptr [xmsControl + 2], es
        pop  es
      end;
      asm
        mov  ah, 0Ah
        mov  dx, [xmsHandle]
        call [XmsControl]
      end;
    end;
  {$ENDIF}
  Memory.Create(InterfaceMemory);
  WriteLn('Memory manager initialized.');
  if (Memory.XmsEnabled) then
  begin
    WriteLn
    (
      'XMS memory enabled.',
      #10#13,
      longint(Memory.LowerMemAvail),
      ' bytes lower memory available.',
      #10#13,
      longint(Memory.XmsMemAvail),
      ' bytes XMS memory available.'
    );
  end;
  InitMouse;
  HideMouse;
  WriteLn('Mouse initialized.');
{  Keyboard.Create;}
  Closed := false;
end;

procedure TApplication.Run;
begin
  repeat
    ProcessEvents;
    MainLoop;
  until Closed;
end;

procedure TApplication.ProcessEvents;
begin
end;

procedure TApplication.Close;
begin
  Closed := true;
end;

procedure TApplication.MainLoop;
begin
end;

destructor TApplication.Done;
begin
  TObject.Done;
  Memory.Done;
{  Keyboard.Done;}
  while KeyPressed do ReadKey;
end;

end.