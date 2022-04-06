unit VgaTxDrv;

interface

uses
  Objects,
  WideStr,
  Collects,
  Utils,
  Drawing,
  Crt,
  TextDrv;

type
  PVgaTextDriver = ^TVgaTextDriver;
  TVgaTextDriver = object(TTextDriver)
  private
    function GetTextAttributes(fore, back: byte; doBlink: boolean): byte; virtual;
  public
    procedure Write(const txt: string); virtual;
    procedure WriteWide(txt: TWideString); virtual;
    procedure SetForeColor(color: byte); virtual;
    procedure SetBackColor(color: byte); virtual;
    procedure SetBlink(doBlink: boolean); virtual;
    procedure Init; virtual;
    procedure SetMode(newMode: TTextMode); virtual;
    procedure HLine(x1, y1, width: byte; lineStyle: TLineStyle); virtual;
    procedure VLine(x1, y1, width: byte; lineStyle: TLineStyle); virtual;
    procedure Box(rect: TRect; style: TLineStyle); virtual;
    procedure SetXY(newX, newY: byte); virtual;
    procedure CursorOn; virtual;
    procedure CursorOff; virtual;
    procedure ClrScr; virtual;
    destructor Done; virtual;
  end;

implementation

type
  TVga80x25Screen = array[0..24, 0..79] of byte;

var
  _currentScreen: PByte;


procedure TVgaTextDriver.SetMode(newMode: TTextMode);
begin
  Mode.Assign(newMode);
  CursorOn;
end;

procedure TVgaTextDriver.SetXY(newX, newY: byte);
begin
  TTextDriver.SetXY(newX, newY);
  GotoXY(newX + 1, newY + 1);
end;

procedure TVgaTextDriver.Write(const txt: string);
var
  ch: TTextChar;
  index: integer;
  offset: PByte;
  cursorState: boolean;
begin
  cursorState := State.IsCursorOn;
  if CursorState then CursorOff;
  offset := Ptr($B800, $0000);
  Inc(offset, 2 * (State.Y * Mode.Width + State.X));
  ch.Attributes := State.Attributes;
  for index := 1 to Length(txt) do begin
    ch.Character := txt[index];
    Move(ch, offset^, 2);
    Inc(offset, 2);
    State.X := State.X + 1;
    if (state.X > Mode.MaxX) then begin
      state.X := 0;
      State.Y := State.Y + 1;
      if (state.Y > Mode.MaxY) then break;
    end;
  end;
  SetXY(state.X, state.Y);
  if CursorState then CursorOn;
end;

procedure TVgaTextDriver.WriteWide(txt: TWideString);
var
  ch: TTextChar;
  index: integer;
  offset: PByte;
  cursorState: boolean;
begin
  cursorState := State.IsCursorOn;
  if CursorState then CursorOff;
  offset := Ptr($B800, $0000);
  Inc(offset, 2 * (State.Y * Mode.Width + State.X));
  ch.Attributes := State.Attributes;
  for index := 1 to txt.Len do begin
    ch.Character := txt.GetChar(index);
    Move(ch, offset^, 2);
    Inc(offset, 2);
    State.X := State.X + 1;
    if (state.X > Mode.MaxX) then begin
      state.X := 0;
      State.Y := State.Y + 1;
      if (state.Y > Mode.MaxY) then break;
    end;
  end;
  SetXY(state.X, state.Y);
  if CursorState then CursorOn;
end;

procedure TVgaTextDriver.SetBlink(doBlink: boolean);
begin
  TTextDriver.SetBlink(doBlink);
  State.Attributes := GetTextAttributes(State.ForeColor, State.BackColor, State.Blink);
end;

procedure TVgaTextDriver.SetForeColor(color: byte);
begin
  TTextDriver.SetForeColor(color);
  State.Attributes := GetTextAttributes(State.ForeColor, State.BackColor, State.Blink);
end;

procedure TVgaTextDriver.SetBackColor(color: byte);
begin
  TTextDriver.SetBackColor(color);
  State.Attributes := GetTextAttributes(State.ForeColor, State.BackColor, State.Blink);
end;

procedure TVgaTextDriver.CursorOn;
begin
  TTextDriver.CursorOn;
  asm
    mov   ax,[Seg0040]
    mov   es,ax
    mov   di,0060h
    mov   cx,word ptr es:[di]
    mov   ax,0100h
    and   ch,0dfh
    int   10h
  end;
end;

procedure TVgaTextDriver.CursorOff;
begin
  TTextDriver.CursorOff;
  asm
    mov   ax,[Seg0040]
    mov   es,ax
    mov   di,0060h
    mov   cx,word ptr es:[di]
    mov   ax,0100h
    or    ch,20h
    int   10h
  end;
end;

function TVgaTextDriver.GetTextAttributes(fore, back: byte; doBlink: boolean): byte;
var
  blinkByte : byte;
begin
  blinkByte := 0;
  if (doBlink) then blinkByte := 1;
  GetTextAttributes := fore or (back shl 4) or (byte(doBlink) shl 7);
end;

procedure TVgaTextDriver.Init;
var
  newMode: PTextMode;
begin
  TTextDriver.Init;
  TypeName := 'TVgaTextDriver';
  newMode := New(PTextMode, CreateEmpty);
  with newMode^ do begin
    Width := 80;
    Height := 25;
    MaxX := 79;
    MaxY := 24;
    Name := 'Text 80x25 16 color';
    AdditionalData := 0;
    Description := 'VGA Text 80x25x16 color';
    HelpText := '';
    Modes.Add(newMode);
  end;
  newMode := New(PTextMode, CreateEmpty);
  with newMode^ do begin
    Width := 80;
    Height := 50;
    MaxX := 79;
    MaxY := 49;
    Name := 'Text 80x50 16 color';
    AdditionalData := 0;
    Description := 'VGA Text 80x50x16 color';
    HelpText := '';
    Modes.Add(newMode);
  end;
end;

procedure TVgaTextDriver.HLine(x1, y1, width: byte; lineStyle: TLineStyle);
begin
end;

procedure TVgaTextDriver.VLine(x1, y1, width: byte; lineStyle: TLineStyle);
begin
end;

procedure TVgaTextDriver.Box(rect: TRect; style: TLineStyle);
begin
end;

procedure TVgaTextDriver.ClrScr;
var
  ch: TTextChar;
  index: integer;
  offset: PByte;
  line, linePtr: PByte;
begin
  GetMem(line, Mode.Width * 2);
  offset := Ptr($B800, $0000);
  ch.Attributes := State.Attributes;
  ch.Character := #32;
  linePtr := line;
  for index := 0 to Mode.MaxX do begin
    Move(ch, linePtr^, 2);
    Inc(linePtr, 2);
  end;
  for index := 0 to Mode.MaxY do begin
    Move(line^, offset^, Mode.Width * 2);
    Inc(offset, Mode.Width * 2);
  end;
  SetXY(0, 0);
  FreeMem(line, Mode.Width * 2);
end;

destructor TVgaTextDriver.Done;
begin
  TTextDriver.Done;
end;

end.