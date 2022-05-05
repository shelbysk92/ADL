{$I COMPILER.INC}
unit CrtTxDrv;

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
  PCrtTextDriver = ^TCrtTextDriver;
  TCrtTextDriver = object(TTextDriver)
  private
    _startMode: word;
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

procedure TCrtTextDriver.SetMode(newMode: PTextMode);
begin
  Mode := newMode;
  if (Pos('8x8', newMode^.Id) = 0) then begin
    Mode^.MaxY := Hi(WindMax);
    TextMode(Mode^.AdditionalData + Font8x8);
  end;
  _startMode := LastMode;
  TextMode(Mode^.AdditionalData);
  ClrScr;
  CursorOn;
end;

procedure TCrtTextDriver.SetXY(newX, newY: byte);
begin
  TTextDriver.SetXY(newX, newY);
  GotoXY(newX + 1, newY + 1);
end;

procedure TCrtTextDriver.Write(const txt: string);
var
  ch: TTextChar;
  index: integer;
begin
  if (WhereY = Mode^.MaxY) and (WhereX + length(txt) = 80) then
    Inc(WindMax);
  System.Write(txt);
  if (WhereY = Mode^.MaxY) and (WhereX + length(txt) = 80) then
    Dec(WindMax);
  SetXY(WhereX - 1, WhereY - 1);
end;

procedure TCrtTextDriver.WriteWide(txt: TWideString);
var
  index: integer;
  ch: char;
begin
  for index := 1 to txt.Len do begin
    ch := txt.GetChar(index);
    System.Write(ch);
  end;
  SetXY(WhereX - 1, WhereY - 1);
end;

procedure TCrtTextDriver.SetBlink(doBlink: boolean);
begin
  TTextDriver.SetBlink(doBlink);
  if (doBlink and (TextAttr < 15)) then TextColor(State^.ForeColor + blink);
  if ((not doBlink) and (TextAttr > 15)) then TextColor(State^.ForeColor);
end;

procedure TCrtTextDriver.SetForeColor(color: byte);
begin
  TTextDriver.SetForeColor(color);
  TextColor(color);
end;

procedure TCrtTextDriver.SetBackColor(color: byte);
begin
  TTextDriver.SetBackColor(color);
  TextBackground(color);
end;

procedure TCrtTextDriver.CursorOn;
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

procedure TCrtTextDriver.CursorOff;
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

function TCrtTextDriver.GetTextAttributes(fore, back: byte; doBlink: boolean): byte;
var
  blinkByte : byte;
begin
  blinkByte := 0;
  if (doBlink) then blinkByte := 1;
  GetTextAttributes := fore or (back shl 4) or (byte(doBlink) shl 7);
end;

procedure TCrtTextDriver.Init;
var
  newMode: PTextMode;
begin
  TTextDriver.Init;
  TypeName := 'TCrtTextDriver';
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
    Id := 'C0408x8';
    Width := 40;
    Height := 25;
    MaxX := 39;
    MaxY := 24;
    Name := 'CO40';
    AdditionalData := CO40;
    Description := '40x25 color on color adapter with 8x8 font';
    HelpText := '';
    Modes^.Add(newMode);
  end;
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
    Id := 'C0808x8';
    Width := 80;
    Height := 50;
    MaxX := 79;
    MaxY := 49;
    Name := 'CO80';
    AdditionalData := CO80;
    Description := '40x25 color on color adapter with 8x8 font';
    HelpText := '';
    Modes^.Add(newMode);
  end;
end;

procedure TCrtTextDriver.HLine(x1, y1, width: byte; lineStyle: TLineStyle);
var
  ch: char;
  index: integer;
  cursorState: boolean;
begin
  PushState;
  CursorOff;
  ch := #196;
  if (lineStyle = lsDouble) then ch := #205;
  SetXY(x1, y1);
  for index := 0 to width - 1 do begin
    Write(ch);
  end;
  PopState;
  SetXY(State^.X, State^.Y);
end;

procedure TCrtTextDriver.VLine(x1, y1, height: byte; lineStyle: TLineStyle);
var
  ch: char;
  index: integer;
  cursorState: boolean;
begin
  PushState;
  CursorOff;
  ch := #179;
  if (lineStyle = lsDouble) then ch := #186;
  for index := y1 to y1 + height - 1 do begin
    Write(ch);
  end;
  PopState;
  SetXY(State^.X, State^.Y);
end;

procedure TCrtTextDriver.Box(rect: TRect; style: TLineStyle);
var
  ch: char;
  offset: PByte;
begin
  PushState;
  ch := #218;
  if (style = lsDouble) then ch := #201;
  SetXY(rect.X, rect.Y);
  Write(ch);

  ch := #191;
  if (style = lsDouble) then ch:= #187;
  SetXY(rect.X + rect.width - 1, rect.Y);
  Write(ch);

  ch := #192;
  if (style = lsDouble) then ch := #200;
  SetXY(rect.X, rect.Y + rect.Height - 1);
  Write(ch);

  ch := #217;
  if (style = lsDouble) then ch := #188;
  SetXY(rect.X + rect.Width - 1, rect.Y + rect.Height - 1);
  Write(ch);

  HLine(rect.X + 1, rect.Y, rect.Width - 2, style);
  HLine(rect.X + 1, rect.Y + rect.Height - 1, rect.Width - 2, style);
  VLine(rect.X, rect.Y + 1, rect.Height - 2, style);
  VLine(rect.X + rect.Width - 1, rect.Y + 1, rect.Height - 2, style);
  PopState;
end;

procedure TCrtTextDriver.ClrScr;
var
  rect: TRect;
begin
  rect.Create(0, 0, Mode^.Width, Mode^.Height);
  FillRect(Rect);
end;

procedure TCrtTextDriver.FillRect(rect: TRect);
var
  index: integer;
  line: string;
begin
  PushState;
  FillChar(line, 255, 32);
  line[0] := chr(rect.Width);
  for index := rect.Y to rect.Bottom do begin
    SetXY(rect.X, index);
    Write(line);
  end;
  PopState;
end;

destructor TCrtTextDriver.Done;
begin
  TTextDriver.Done;
  TextMode(_startMode);
end;

begin
end.