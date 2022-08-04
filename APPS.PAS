{$I COMPILER.INC}
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
begin
  TObject.Init;
  TypeName := 'TApplication';
  ClrScr;
  MouseDriver := New(PMouseDriver, Create);
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
  Dispose(MouseDriver, Done);
{  Keyboard.Done;}
  while KeyPressed do ReadKey;
  TObject.Done;
end;

end.