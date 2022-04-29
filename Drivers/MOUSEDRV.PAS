{$I Compiler.inc}
unit MouseDrv;

interface

uses
  Objects,
  Collects;

const
  InitMouseCode = $00;
  ShowMouseCode = $01;
  HideMouseCode = $02;
  GetMouseStatusCode = $03;

type
  TButtonState =
  (
    bsLeft,
    bsRight
  );
  TButtonStates = set of TButtonState;
  PMouseState = ^TMouseState;
  TMouseState = object(TPersistent)
  private
  public
    X, Y: integer;
    ButtonState: TButtonStates;
    Visible: boolean;
    procedure Init; virtual;
    procedure Assign(var source: TPersistent); virtual;
    procedure AssignTo(var dest: TPersistent); virtual;
    function Moved(state: TMouseState): boolean; virtual;
    function Equals(state: TMouseState): boolean;
    destructor Done; virtual;
  end;
  PMouseDriver = ^PMouseDriver;
  TMouseDriver = object(TObject)
  private
  public
    State: TMouseState;
    _stateStack: PStack;
    procedure Init; virtual;
    procedure ShowMouse; virtual;
    procedure HideMouse; virtual;
    procedure PushState; virtual;
    procedure PopState; virtual;
    procedure GetMouseState(var currentState: TMouseState); virtual;
    procedure InitMouseCursor; virtual;
    procedure SetMouseResolution(width, height: word); virtual;
    destructor Done; virtual;
  end;

var
  MouseDriver: TMouseDriver;

implementation

uses
  Dos, DosConst;

const
  MouseCursor: array[0..31] of word =
  (
    $7FFF,
    $3FFF,
    $1FFF,
    $0FFF,
    $07FF,
    $03FF,
    $3FFF,
    $7FFF,
    $FFFF,
    $FFFF,
    $FFFF,
    $FFFF,
    $FFFF,
    $FFFF,
    $FFFF,
    $FFFF,

    $0000,
    $0000,
    $4000,
    $6000,
    $7000,
    $4000,
    $0000,
    $0000,
    $0000,
    $0000,
    $0000,
    $0000,
    $0000,
    $0000,
    $0000,
    $0000

{
      0111111111111111
      0011111111111111
      0001111111111111
      0000111111111111
      0000011111111111
      0000001111111111
      0011111111111111
      0111111111111111
      1111111111111111
      1111111111111111
      1111111111111111
      1111111111111111
      1111111111111111
      1111111111111111
      1111111111111111
      1111111111111111

      0000000000000000
      0000000000000000
      0100000000000000
      0110000000000000
      0111000000000000
      0100000000000000
      0000000000000000
      0000000000000000
      0000000000000000
      0000000000000000
      0000000000000000
      0000000000000000
      0000000000000000
      0000000000000000
      0000000000000000
      0000000000000000
    }
  );

procedure TMouseState.Init;
begin
  TObject.Init;
  TypeName := 'TMouseState';
  X := 0;
  Y := 0;
  ButtonState := [];
  Visible := false;
end;

destructor TMouseState.Done;
begin
end;

function TMouseState.Equals(state: TMouseState): boolean;
begin
  Equals := (state.X = X) and (state.Y = Y) and (state.ButtonState = ButtonState);
end;

procedure TMouseState.Assign(var source: TPersistent);
var
  state: PMouseState;
begin
  state := PMouseState(@source);
  X := state^.X;
  Y := state^.Y;
  ButtonState := state^.ButtonState;
  Visible := state^.Visible;
end;

procedure TMouseState.AssignTo(var dest: TPersistent);
var
  state: PMouseState;
begin
  state := PMouseState(@dest);
  state^.X := X;
  state^.Y := Y;
  state^.ButtonState := ButtonState;
  state^.Visible := Visible;
end;

function TMouseState.Moved(state: TMouseState): boolean;
begin
  Moved := (state.X <> X) or (state.Y <> Y);
end;

procedure TMouseDriver.InitMouseCursor;
var
  reg: Registers;
begin
  FillChar(reg, SizeOf(reg), 0);
  reg.AX := $09;
  reg.BX := 0;
  reg.CX := 0;
  reg.ES := Seg(MouseCursor);
  reg.DX := Ofs(MouseCursor);
  Intr($33, reg);
end;

destructor TMouseDriver.Done;
begin
  Dispose(_stateStack);
  State.Done;
end;

procedure TMouseDriver.Init;
var
  reg: Registers;
  success: boolean;
begin
  success := false;
  FillChar(reg, SizeOf(reg), 0);
  reg.AX := InitMouseCode;
  Intr(MouseInterrupt, reg);
  success := Reg.AX = $FFFF;
  State.Create;
  if success then InitMouseCursor;
  _stateStack := New(PStack, Create);
end;

procedure TMouseDriver.ShowMouse;
var
  reg: Registers;
begin;
  FillChar(reg, SizeOf(reg), 0);
  reg.AX := ShowMouseCode;
  Intr(MouseInterrupt, reg);
  State.Visible := true;
end;

procedure TMouseDriver.HideMouse;
var
  reg: Registers;
begin;
  FillChar(reg, SizeOf(reg), 0);
  reg.AX := HideMouseCode;
  Intr(MouseInterrupt, reg);
  State.Visible := false;
end;

procedure TMouseDriver.PushState;
var
  newState: PMouseState;
begin
  newState := New(PMouseState, Create);
  newState^.Assign(State);
  _stateStack^.Push(newState);
end;

procedure TMouseDriver.PopState;
var
  newState: PMouseState;
begin
  newState := PMouseState(_stateStack^.Pop);
  if (newState = nil) then exit;
  State.Assign(newState^);
  Dispose(newState, Done);
  if (State.Visible) then ShowMouse
  else HideMouse;
end;

procedure TMouseDriver.SetMouseResolution(width, height: word);
begin
  Dec(width, 1);
  Dec(height, 1);
  asm
    mov  ax, 7h
    mov  cx, 0
    mov  dx, [width]
    int  33h
    mov  ax, 8h
    mov  cx, 0
    mov  dx, [height]
    int  33h
  end;
end;

procedure TMouseDriver.GetMouseState(var currentState: TMouseState);
var
  reg: Registers;
begin
  FillChar(reg, SizeOf(reg), 0);
  currentState.Create;
  reg.AX := GetMouseStatusCode;
  Intr(MouseInterrupt, reg);
  currentState.X := reg.CX;
  currentState.Y := reg.DX;
  if (reg.BX and $01 > 0) then
    Include(currentState.ButtonState, bsLeft);
  if (reg.BX and $02 > 0) then
    Include(currentState.ButtonState, bsRight);
end;

end.