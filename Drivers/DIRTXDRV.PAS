unit DirTxDrv;

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
  PDirectTextDriver = ^TDirectTextDriver;
  TDirectTextDriver = object(TTextDriver)
  private
    _startMode: byte;
    function GetTextAttributes(fore, back: byte; doBlink: boolean): byte; virtual;
  public
    procedure Write(const txt: string); virtual;
    procedure WriteWide(txt: TWideString); virtual;
    procedure SetForeColor(color: byte); virtual;
    procedure SetBackColor(color: byte); virtual;
    procedure SetBlink(doBlink: boolean); virtual;
    procedure Init; virtual;
    procedure SetMode(newMode: PTextMode); virtual;
    procedure HLine(x1, y1, width: byte; lineStyle: TLineStyle); virtual;
    procedure VLine(x1, y1, height: byte; lineStyle: TLineStyle); virtual;
    procedure Box(rect: TRect; style: TLineStyle); virtual;
    procedure FillRect(rect: TRect); virtual;
    procedure SetXY(newX, newY: byte); virtual;
    procedure CursorOn; virtual;
    procedure CursorOff; virtual;
    procedure ClrScr; virtual;
    destructor Done; virtual;
  end;

implementation

const
  ColorScreen: PByte = Ptr($B800, $0000);
  MonoScreen: PByte = Ptr($B000, $000);

type
  TColor80x25Screen = array[0..24, 0..79] of byte;

var
  _currentScreen: PByte;

procedure TDirectTextDriver.SetMode(newMode: PTextMode);
begin
  Mode := newMode;
  _startMode := LastMode;
  if (newMode^.Id = 'Mono') then
    _currentScreen := MonoScreen
  else
    _currentScreen := ColorScreen;
  TextMode(Mode^.AdditionalData);
  Mode^.Height := Hi(WindMax) + 1;
  Mode^.MaxY := Hi(WindMax);
  ClrScr;
  CursorOn;
end;

procedure TDirectTextDriver.SetXY(newX, newY: byte);
begin
  TTextDriver.SetXY(newX, newY);
  GotoXY(newX + 1, newY + 1);
end;

procedure TDirectTextDriver.Write(const txt: string);
var
  ch: TTextChar;
  index: integer;
  offset: PByte;
begin
  offset := _currentScreen;
  Inc(offset, 2 * (State^.Y * Mode^.Width + State^.X));
  ch.Attributes := State^.Attributes;
  for index := 1 to Length(txt) do begin
    ch.Character := txt[index];
    Move(ch, offset^, 2);
    Inc(offset, 2);
    State^.X := State^.X + 1;
    if (state^.X > Mode^.MaxX) then begin
      state^.X := 0;
      State^.Y := State^.Y + 1;
      if (state^.Y > Mode^.MaxY) then break;
    end;
  end;
  SetXY(state^.X, state^.Y);
end;

procedure TDirectTextDriver.WriteWide(txt: TWideString);
var
  ch: TTextChar;
  index: integer;
  offset: PByte;
begin
  offset := _currentScreen;
  Inc(offset, 2 * (State^.Y * Mode^.Width + State^.X));
  ch.Attributes := State^.Attributes;
  for index := 1 to txt.Len do begin
    ch.Character := txt.GetChar(index);
    Move(ch, offset^, 2);
    Inc(offset, 2);
    State^.X := State^.X + 1;
    if (state^.X > Mode^.MaxX) then begin
      State^.X := 0;
      State^.Y := State^.Y + 1;
      if (State^.Y > Mode^.MaxY) then break;
    end;
  end;
  SetXY(state^.X, state^.Y);
end;

procedure TDirectTextDriver.SetBlink(doBlink: boolean);
begin
  TTextDriver.SetBlink(doBlink);
  State^.Attributes := GetTextAttributes(State^.ForeColor, State^.BackColor, State^.Blink);
end;

procedure TDirectTextDriver.SetForeColor(color: byte);
begin
  TTextDriver.SetForeColor(color);
  State^.Attributes := GetTextAttributes(State^.ForeColor, State^.BackColor, State^.Blink);
end;

procedure TDirectTextDriver.SetBackColor(color: byte);
begin
  TTextDriver.SetBackColor(color);
  State^.Attributes := GetTextAttributes(State^.ForeColor, State^.BackColor, State^.Blink);
end;

procedure TDirectTextDriver.CursorOn;
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

procedure TDirectTextDriver.CursorOff;
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

function TDirectTextDriver.GetTextAttributes(fore, back: byte; doBlink: boolean): byte;
var
  blinkByte : byte;
begin
  blinkByte := 0;
  if (doBlink) then blinkByte := 1;
  GetTextAttributes := fore or (back shl 4) or (byte(doBlink) shl 7);
end;

procedure TDirectTextDriver.Init;
var
  newMode: PTextMode;
begin
  TTextDriver.Init;
  TypeName := 'TDirectTextDriver';
  newMode := New(PTextMode, CreateEmpty);
  with newMode^ do begin
    Id := 'BW40';
    Width := 40;
    Height := 25;
    MaxX := 39;
    MaxY := 24;
    Name := 'BW40';
    AdditionalData := BW40;
    Description := '40x25 B/W on color adapter';
    HelpText := '';
    Modes^.Add(newMode);
  end;
  newMode := New(PTextMode, CreateEmpty);
  with newMode^ do begin
    Id := 'BW80';
    Width := 80;
    Height := 25;
    MaxX := 79;
    MaxY := 24;
    Name := 'BW80';
    AdditionalData := BW80;
    Description := '80x25 B/W on color adapter';
    HelpText := '';
    Modes^.Add(newMode);
  end;
  newMode := New(PTextMode, CreateEmpty);
  with newMode^ do begin
    Id := 'Mono';
    Width := 80;
    Height := 25;
    MaxX := 79;
    MaxY := 24;
    Name := 'Mono';
    AdditionalData := Mono;
    Description := '80x25 B/W on monochrome adapter';
    HelpText := '';
    Modes^.Add(newMode);
  end;
  newMode := New(PTextMode, CreateEmpty);
  with newMode^ do begin
    Id := 'CO40';
    Width := 40;
    Height := 25;
    MaxX := 39;
    MaxY := 24;
    Name := 'CO40';
    AdditionalData := CO40;
    Description := '40x25 color on color adapter';
    HelpText := '';
    Modes^.Add(newMode);
  end;
  newMode := New(PTextMode, CreateEmpty);
  with newMode^ do begin
    Id := 'CO408x8';
    Width := 40;
    Height := 25;
    MaxX := 39;
    MaxY := 24;
    Name := 'CO40';
    AdditionalData := CO40 + Font8x8;
    Description := '40x25 color on color adapter with 8x8 font';
    HelpText := '';
    Modes^.Add(newMode);
  end;
  newMode := New(PTextMode, CreateEmpty);
  with newMode^ do begin
    Id := 'CO80';
    Width := 80;
    Height := 25;
    MaxX := 79;
    MaxY := 24;
    Name := 'CO80';
    AdditionalData := CO80;
    Description := '80x25 color on color adapter';
    HelpText := '';
    Modes^.Add(newMode);
  end;
  newMode := New(PTextMode, CreateEmpty);
  with newMode^ do begin
    Id := 'CO808x8';
    Width := 80;
    Height := 50;
    MaxX := 79;
    MaxY := 49;
    Name := 'CO80';
    AdditionalData := CO80 + Font8x8;
    Description := '80x25 color on color adapter with 8x8 font';
    HelpText := '';
    Modes^.Add(newMode);
  end;
end;

procedure TDirectTextDriver.HLine(x1, y1, width: byte; lineStyle: TLineStyle);
var
  ch: TTextChar;
  index: integer;
  offset: PByte;
  cursorState: boolean;
begin
  cursorState := State^.IsCursorOn;
  if CursorState then CursorOff;
  ch.Attributes := State^.Attributes;
  ch.Character := #196;
  if (lineStyle = lsDouble) then ch.Character := #205;
  Offset := _currentScreen;
  Inc(offset, 2 * (y1 * Mode^.Width + x1));
  for index := 0 to width - 1 do begin
    Move(ch, offset^, 2);
    Inc(offset, 2);
  end;
  if CursorState then CursorOn;
end;

procedure TDirectTextDriver.VLine(x1, y1, height: byte; lineStyle: TLineStyle);
var
  ch: TTextChar;
  index: integer;
  offset: PByte;
  cursorState: boolean;
begin
  cursorState := State^.IsCursorOn;
  if CursorState then CursorOff;
  ch.Attributes := State^.Attributes;
  ch.Character := #179;
  if (lineStyle = lsDouble) then ch.Character := #186;
  offset := _currentScreen;
  Inc(offset, 2 * (y1 * Mode^.Width + x1));
  for index := y1 to y1 + height - 1 do begin
    Move(ch, offset^, 2);
    Inc(offset, 2 * Mode^.Width);
  end;
  if CursorState then CursorOn;
end;

procedure TDirectTextDriver.Box(rect: TRect; style: TLineStyle);
var
  ch: TTextChar;
  offset: PByte;
begin
  ch.Attributes := State^.Attributes;

  ch.Character := #218;
  if (style = lsDouble) then ch.Character := #201;
  offset := _currentScreen;
  Inc(offset, 2 * (rect.Y * Mode^.Width + rect.X));
  Move(ch, offset^, 2);

  ch.Character := #191;
  if (style = lsDouble) then ch.Character := #187;
  offset := _currentScreen;
  Inc(offset, 2 * (rect.Y * Mode^.Width + rect.X + rect.Width - 1));
  Move(ch, offset^, 2);

  ch.Character := #192;
  if (style = lsDouble) then ch.Character := #200;
  offset := _currentScreen;
  Inc(offset, 2 * ((rect.Y + rect.Height - 1) * Mode^.Width + rect.X));
  Move(ch, offset^, 2);

  ch.Character := #217;
  if (style = lsDouble) then ch.Character := #188;
  offset := _currentScreen;
  Inc(offset, 2 * ((rect.Y + rect.Height - 1) * Mode^.Width + rect.X + rect.Width - 1));
  Move(ch, offset^, 2);

  HLine(rect.X + 1, rect.Y, rect.Width - 2, style);
  HLine(rect.X + 1, rect.Y + rect.Height - 1, rect.Width - 2, style);
  VLine(rect.X, rect.Y + 1, rect.Height - 2, style);
  VLine(rect.X + rect.Width - 1, rect.Y + 1, rect.Height - 2, style);
end;

procedure TDirectTextDriver.ClrScr;
var
  rect: TRect;
begin
  rect.Create(0, 0, Mode^.Width, Mode^.Height);
  FillRect(Rect);
end;

procedure TDirectTextDriver.FillRect(rect: TRect);
var
  ch: TTextChar;
  index: integer;
  offset: PByte;
  line, linePtr: PByte;
begin
  GetMem(line, rect.Width * 2);
  offset := _currentScreen;
  ch.Attributes := State^.Attributes;
  ch.Character := #32;
  linePtr := line;
  for index := 0 to rect.Width - 1 do begin
    Move(ch, linePtr^, 2);
    Inc(linePtr, 2);
  end;
  Inc(offset, 2 * (rect.Y * Mode^.Width + rect.X));
  for index := rect.Y to rect.Bottom do begin
    Move(line^, offset^, rect.Width * 2);
    Inc(offset, Mode^.Width * 2);
  end;
  SetXY(0, 0);
  FreeMem(line, rect.Width * 2);
end;

destructor TDirectTextDriver.Done;
begin
  TTextDriver.Done;
end;

begin
end.