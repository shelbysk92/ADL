unit Mouse;

interface

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
  TMouseState = record
    X, Y: integer;
    ButtonState: TButtonStates;
  end;

function InitMouse: boolean;
procedure ShowMouse;
procedure HideMouse;
procedure GetMouseState(var state: TMouseState);
procedure InitMouseCursor;

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

procedure InitMouseCursor;
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

function InitMouse: boolean;
var
  reg: Registers;
  success: boolean;
begin
  success := false;
  FillChar(reg, SizeOf(reg), 0);
  reg.AX := InitMouseCode;
  Intr(MouseInterrupt, reg);
  success := Reg.AX = $FFFF;
  if success then InitMouseCursor;
  InitMouse := true;
end;

procedure ShowMouse;
var
  reg: Registers;
begin;
  FillChar(reg, SizeOf(reg), 0);
  reg.AX := ShowMouseCode;
  Intr(MouseInterrupt, reg);
end;

procedure HideMouse;
var
  reg: Registers;
begin;
  FillChar(reg, SizeOf(reg), 0);
  reg.AX := HideMouseCode;
  Intr(MouseInterrupt, reg);
end;

procedure GetMouseState(var state: TMouseState);
var
  reg: Registers;
begin
  FillChar(reg, SizeOf(reg), 0);
  FillChar(state, SizeOf(state), 0);
  reg.AX := GetMouseStatusCode;
  Intr(MouseInterrupt, reg);
  state.X := reg.CX div 8;
  state.Y := reg.DX div 8;
  if (reg.BX and $01 > 0) then
    Include(state.ButtonState, bsLeft);
  if (reg.BX and $02 > 0) then
    Include(state.ButtonState, bsRight);
end;

end.