{$I Compiler.inc}
unit KeyDrv;

interface

uses
  Objects,
  DateTime,
  Utils;

type
  TShiftStates =
  (
    ssNone,
    ssShift,
    ssControl,
    ssAlt
  );
  TShiftState = set of TShiftStates;
  TKeyboardBuffer = array[0..255] of word;
  PKeyboardDriver = ^TKeyboardDriver;
  TKeyboardDriver = object(TBaseObject)
    private
      _keyPressed: boolean;
    public
     constructor Create;
     destructor Done; virtual;
     procedure Init; virtual;
     function BufferLength: byte; virtual;
     function KeyPressed: boolean; virtual;
     function GetKey: word; virtual;
     function NumLock: boolean; virtual;
     function InsertMode: boolean; virtual;
     function ScrollLock: boolean; virtual;
     function CapsLock: boolean; virtual;
     procedure GetBuffer(var buffer: TKeyboardBuffer); virtual;
     procedure ClearBuffer; virtual;
  end;

const
  kAlpha: set of char = ['A'..'Z', 'a'..'z'];
  kNumeric: set of char = ['0'..'9'];
  kAlphaNumeric: set of char = ['A'..'Z', 'a'..'z', '0'..'9'];
  kPuncuation: set of char = ['!'..'/', ':'..'@', '['..'`', '{'..'~'];
  kLeft = 99;
  kRight = 99;
  kUp = 99;
  kDown = 99;
  kCtrlRight = 99;
  kCtrlLeft = 99;
  kPageUp = 99;
  kPageDown = 99;
  kDel = 99;
  kBackSpace = 99;
  kHome = 99;
  kEnd = 99;
  kAltF = 99;
  kAltO = 99;
  kCtrlN = 99;
  kCtrlO = 99;
  kCtrlS = 99;
  kAltX = 99;
  kAltE = 99;
  kCtrlZ = 99;
  kCtrlY = 99;
  kAltS = 99;
  kCtrlF = 99;
  kSpace = 32;
  kAltV = 99;
  kAltH = 99;

implementation

uses
  Dos,
  DosConst,
  Crt;

const
  kcLeftShift = $2A;
  kcRightShift = $36;
  kcControl = $29;
  kcAlt = $56;
  kcCapsLock = $3A;
  kcNumLock = $45;
  kcKeypad0 = $52;
  kcScrollLock = 99;
  kShiftKeys: set of byte =
  [
    kcLeftShift,
    kcRightShift,
    kcAlt,
    kcControl,
    kcNumLock,
    kcScrollLock,
    kcCapsLock
  ];

  {cursor movement keys}
  { printscr/break }

var
  _savedInterruptVector: pointer;
  _keyBufHead: byte absolute $0040:$001A;
  _keyBufTail: byte absolute $0040:$001C;
  _shiftState: TShiftState;
  _capsLock: boolean;
  _numLock: boolean;
  _scrollLock: boolean;
  _insertMode: boolean;
  _memShiftState: byte absolute $0040:$0017;
  _buffer: TKeyboardBuffer;
  _bufferLength: byte;

procedure AddToBuffer(key: word);
begin
  if (_bufferLength < High(_bufferLength)) then
  begin
    Inc(_bufferLength);
    _buffer[_bufferLength] := key;
  end;
end;

procedure KeyboardHandler(Flags, CS, IP, AX, BX, CX, DX, SI, DI, DS, ES, BP: word); interrupt;
var
  data: byte;
  down: boolean;
begin
  asm
    pushf
    call _savedInterruptVector
  end;
  data := port[$60];
  down := false;
  down := data shr 7 = 0;
  if (not down) then
    data := data and $7F;
  if (down) then
  begin
    case data of
      kcLeftShift, kcRightShift: Include(_shiftState, ssShift);
      kcControl: Include(_shiftState, ssControl);
      kcAlt: Include(_shiftState, ssAlt);
      kcCapsLock: _capsLock := true;
      kcNumLock: _numLock := true;
      kcKeypad0: if (_numLock) then _insertMode := not _insertMode;
    end;
  end
  else
  begin
    case data of
      kcLeftShift, kcRightShift: Exclude(_shiftState, ssShift);
      kcControl: Exclude(_shiftState, ssControl);
      kcAlt: Exclude(_shiftState, ssAlt);
      kcCapsLock: _capsLock := false;
      kcNumLock: _numLock := false;
    end;
  end;

  if (_bufferLength < Hi(_bufferLength))
     and not (data in kShiftKeys)
     and not ((not _numLock) and (data = kcKeypad0))
    then
  begin
    AddToBuffer((byte(_shiftState) shl 8) or data);
  end;

  asm
    { send EOI to XT keyboard }
    in  al, 61h
    mov ah, al
    or  al, 80h
    out 61h, al
    mov al, ah
    out 61h, al

    { send EOI to master PIC }
    mov al, 20h
    out 20h, al
  end;

{  TextColor(Black);
  TextBackground(LightGray);
  GotoXY(26, 3);
  Write('Key: ', IntToHex(data), '    ');
  GotoXY(26, 4);
  Write('Num Lock: ', _numLock, '    ');
  GotoXY(26, 5);
  Write('Caps Lock: ', _capsLock, '    ');
  GotoXY(26, 6);
  Write('Insert: ', _insertMode, '    ');
  GotoXY(26, 9);
  Write('Shift: ', ssShift in _shiftState, '    ');
  GotoXY(26, 10);
  Write('Alt: ', ssAlt in _shiftState, '    ');
  GotoXY(26, 11);
  Write('Control: ', ssControl in _shiftState, '    ');
  GotoXY(26, 12);
  Write('Key Down: ', down, '    ');}

  { clear bios keyboard buffer }
  _keyBufHead := $20;
  _keyBufTail := $20;
end;

constructor TKeyboardDriver.Create;
begin
  Init;
  _shiftState := [];
end;

procedure TKeyboardDriver.Init;
begin
  FillChar(_buffer, SizeOf(_buffer), 0);
  _bufferLength := 0;
  _keyPressed := false;
  _capsLock := _memShiftState and $0040 <> 0;
  _numLock := _memShiftState and $0020 <> 0;
  _insertMode := true;
  GetIntVec($09, _savedInterruptVector);
  SetIntVec($09, @KeyboardHandler);
end;

destructor TKeyboardDriver.Done;
begin
  SetIntVec($09, _savedInterruptVector);
end;

function TKeyboardDriver.BufferLength: byte;
begin
end;

function TKeyboardDriver.KeyPressed: boolean;
begin
  KeyPressed := _keyPressed;
end;

function TKeyboardDriver.GetKey: word;
begin
  if (not _keyPressed) then exit;
end;

procedure TKeyboardDriver.GetBuffer(var buffer: TKeyboardBuffer);
begin
  FillChar(buffer, SizeOf(buffer), 0);
  Move(_buffer, buffer, _bufferLength);
end;

procedure TKeyboardDriver.ClearBuffer;
begin
  FillChar(_buffer, SizeOf(_buffer), 0);
  _bufferLength := 0;
end;

function TKeyboardDriver.NumLock: boolean;
begin
  NumLock := _numLock;
end;

function TKeyboardDriver.InsertMode: boolean;
begin
  InsertMode := _insertMode;
end;

function TKeyboardDriver.CapsLock: boolean;
begin
  CapsLock := _capsLock;
end;

function TKeyboardDriver.ScrollLock: boolean;
begin
  ScrollLock := _scrollLock;
end;


begin
end.