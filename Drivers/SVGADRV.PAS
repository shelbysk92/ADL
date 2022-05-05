{$I COMPILER.INC}
unit SVgaDrv;

interface

uses
  Objects,
  GraphDrv,
  Utils,
  WideStr,
  Drawing;

type
  PVbeInfo = ^TVbeInfo;
  TVbeInfo = record
    VbeSignature: array[0..3] of char;
    VbeVersion: word;
    OemStringPtr: pointer;
    Capabilities: longint;
    VideoModes: pointer;
    TotalMemory: word;
    SoftwareRevision: word;
    Vendor: longint;
    ProductName: pointer;
    ProductRevision: pointer;
    Reserved: array[0..221] of byte;
    OemData: array[0..255] of byte
  end;
  PVbeMode = ^TVbeMode;
  TVbeMode = record
    Attributes: word; {depricated; bit 7 indicates linear fram buffer support}
    WindowA: byte; {depricated}
    WindowB: byte; {depricated}
    Granularity: word; {depricated}
    WindowSize: word;
    SegmentA: word;
    SegmentB: word;
    WinFuncPtr: pointer; {depricated}
    Pitch: word; {bytes per horizontal line}
    Width: word; {width in pixels}
    Height: word; {height in pixels}
    Wchar: char; {unused}
    Ychar: char; {unused}
    Planes: byte;
    Bpp: byte; {bits per pixel}
    Banks: byte; {deprecated; total number of banks in this mode}
    MemoryModel: byte;
    BankSize: byte; {deprecated; size of bank, usually 64k, could be 16k}
    ImagePages: byte;
    Reserved0: byte;
    RedMask: byte;
    RedPosition: byte;
    GreenMask: byte;
    GreenPosition: byte;
    BlueMask: byte;
    BluePosition: byte;
    ReservedMask: byte;
    ReservedPosition: byte;
    DirectColorAttributes: byte;
    FrameBuffer: pointer; {physical address of the frame buffer}
    OffScreenMemOffset: longint;
    OffScreenMemSize: word;
    Reserved1: array[0..205] of byte;
  end;
  PSVgaMode = ^TSvgaMode;
  TSvgaMode = object(TGraphicsMode)
  private
    _vbeMode: TVbeMode;
  public
    procedure Init; virtual;
  end;
  PSVgaDriver = ^TSVgaDriver;
  TSVgaDriver = object(TGraphicsDriver)
  private
    _svgaDriver: integer;
    _currentBank: integer;
    _granularity: longint;
    _winFunc: pointer;
    procedure SwitchBank(bank: word);
  public
    SvgaMode: PSvgaMode;
    function GetPixel(x, y: integer): byte; virtual;
    procedure GetImage(var buffer: PByte; rect: TRect); virtual;
    procedure SetMode(newMode: PGraphicsMode); virtual;
    procedure SetPixel(x, y: integer); virtual;
    procedure DrawText(x, y: integer; text: string); virtual;
    procedure DrawTextW(x, y: integer; text: TWideString); virtual;
    procedure MoveTo(x, y: integer); virtual;
    procedure LineTo(x, y: integer); virtual;
    procedure Line(x1, y1, x2, y2: integer); virtual;
    procedure Rectangle(x1, y1, x2, y2: integer); virtual;
    procedure HLine(x, y, width: integer); virtual;
    procedure VLine(x, y, height: integer); virtual;
    procedure FillRect(rect: TRect); virtual;
    procedure DrawImage(x, y, width, height: integer; image: PByte); virtual;
    procedure Init; virtual;
    destructor Done; virtual;
  end;

implementation

uses
  Globals,
  Dos;

procedure TSvgaMode.Init;
begin
  TGraphicsMode.Init;
  FillChar(_vbeMode, SizeOf(_vbeMode), 0);
end;

procedure TSVgaDriver.Init;
var
  newMode: PSvgaMode;
  oldMode: byte;
  info: TVbeInfo;
  segm, offs: word;
  supported, status: byte;
  modePtr: PWord;
  modeInfo: TVbeMode;
  vbeMode: word;
  colors: string;
  test: PSvgaMode;
  index: integer;
begin
  TGraphicsDriver.Init;
  TypeName := 'TSVgaDriver';
  SvgaMode := nil;
  _currentBank := -1;
  segm := Seg(info);
  offs := Ofs(info);
  _granularity := 0;
  asm
    push es
    mov  ax, 4F00h
    mov  es, [segm]
    mov  di, [offs]
    int  10h
    mov  [supported], al
    mov  [status], ah
    pop  es
  end;
  if (supported <> $4F) or (status <> 0) then begin
    CreateError(error, ecGraphicsNotSupported, esError);
    exit;
  end;

  modePtr := info.VideoModes;
  index := 0;
  while modePtr^ <> $FFFF do begin
    newMode := New(PSVgaMode, Create);
    vbeMode := modePtr^;
    segm := Seg(modeInfo);
    offs := Ofs(modeInfo);
    with newMode^ do begin
      asm
        mov  ax, $4F01
        mov  es, [segm]
        mov  di, [offs]
        mov  cx, [vbeMode]
        int  10h
      end;
      _vbeMode := modeInfo;
      Id := 'SVga'
        + IntToStr(_vbeMode.Width)
        + 'x'
        + IntToStr(_vbeMode.Height)
        + 'x'
        + IntToStr(_vbeMode.Bpp);
      Description := 'SVGA '
        + IntToStr(_vbeMode.Width)
        + 'x'
        + IntToStr(_vbeMode.Height)
        + ' ';
      case _vbeMode.Bpp of
          4: colors := '16';
          8: colors := '256';
          15: colors := '32k';
          16: colors := '64k';
          32: colors := '16m';
      end;
      Description := Description + colors + ' color';
      AdditionalData := vbeMode;
      Width := _vbeMode.Width;
      Height := _vbeMode.Height;
      MaxX := _vbeMode.Width - 1;
      MaxY := _vbeMode.Height - 1;
      Bpp := _vbeMode.Bpp;
      Pitch := _vbeMode.Pitch;
      HelpText := 'Requires a VESA compliant Super VGA card.';
      FrameBuffer := Ptr($A000,$0000);
    end;
    Inc(modePtr);
    Modes.Add(newMode);
    Inc(index);
  end;
end;

function TSVgaDriver.GetPixel(x, y: integer): byte;
var
  offset: longint;
  ptr: PByte;
begin
  offset := x + longint(y) * Mode.Pitch;
  ptr := Mode.FrameBuffer;
  Inc(ptr, offset and $FFFF);
  SwitchBank(offset shr 16);
  GetPixel := ptr^;
end;

procedure TSVgaDriver.SetMode(newMode: PGraphicsMode);
var
  selectedMode: word;
begin
  SvgaMode := PSVgaMode(newMode);
  selectedMode := newMode^.AdditionalData;
  if (bit7 in TBits(Lo(SvgaMode^._vbeMode.Attributes))) then begin
    selectedMode := selectedMode or $4000;
  end;
  asm
    mov   ax, 4F02h
    mov   bx, [selectedMode]
    int   10h
  end;
  if (Error.ErrorCode <> ecNone) then exit;
  SetStandardPalette;
  _granularity := longint(SvgaMode^._vbeMode.Granularity) * 1024 - 1;
  _winFunc := SVgaMode^._vbeMode.WinFuncPtr;
  Mode.Create;
  Mode := SvgaMode^;
end;

procedure TSVgaDriver.SwitchBank(bank: word);
var
  winFunc: pointer;
begin
  if (bank = _currentBank) then exit;
  _currentBank := bank;
  winFunc := _winFunc;
  asm
    mov  bh, 0
    mov  bl, 0
    mov  dx, [bank]
    call [winFunc]

    mov  bh, 0
    mov  bl, 1
    mov  dx, [bank]
    call [winFunc]
  end;
end;

procedure TSVgaDriver.SetPixel(x, y: integer);
var
  offset: longint;
  ptr: PByte;
begin
  offset := x + longint(y) * Mode.Pitch;
  ptr := Mode.FrameBuffer;
  Inc(ptr, offset and $FFFF);
  SwitchBank(offset shr 16);
  ptr^ := State.ForeColor;
end;

procedure TSVgaDriver.DrawText(x, y: integer; text: string);
var
  charIndex, xIndex, yIndex, sx, sy, chWidth, MaxX, MaxY: integer;
  ch: char;
  pixel: byte;
  tx: integer;
  color: byte;
begin
  if (Font = nil) then exit;
  PushState;
  maxX := Mode.MaxX;
  maxY := Mode.MaxY;
  for charIndex := 1 to Length(text) do begin
    ch := text[charIndex];
    chWidth := Font^.TextWidth(ch);
    sy := y;
    sx := x + (charIndex - 1) * chWidth;
    for yIndex := 0 to Font^.Height - 1 do begin
      if (sy > MaxY) then exit;
      for xIndex := 0 to chWidth - 1 do begin
        color := State.ForeColor;
        tx := sx + xIndex;
        if (tx > maxX) then break;
        if (not Font^.PixelSet(ch, xIndex, yIndex)) then begin
          State.ForeColor := State.BackColor;
        end;
        SetPixel(tx, sy);
        State.ForeColor := color;
      end;
      Inc(sy);
    end;
    Inc(sx, chWidth);
  end;
  PopState;
end;

procedure TSVgaDriver.DrawTextW(x, y: integer; text: TWideString);
begin
end;

procedure TSVgaDriver.MoveTo(x, y: integer);
begin
end;

procedure TSVgaDriver.LineTo(x, y: integer);
begin
end;

procedure TSVgaDriver.Line(x1, y1, x2, y2: integer);
begin
end;

procedure TSVgaDriver.Rectangle(x1, y1, x2, y2: integer);
begin
end;

procedure TSVgaDriver.HLine(x, y, width: integer);
var
  offset: longint;
  ptr: PByte;
  index: word;
  partialWidth: word;
  ptrOffset: word;
  bank: word;
begin
  offset := x + longint(y) * Mode.Pitch;
  ptr := Mode.FrameBuffer;
  ptrOffset := offset and _granularity;
  Inc(ptr, ptrOffset);
  bank := offset shr 16;
  SwitchBank(bank);
  if (ptrOffset + width > _granularity) then begin
    partialWidth := _granularity - ptrOffset + 1;
    FillChar(ptr^, partialWidth, ForeColor);
    SwitchBank(bank + 1);
    ptr := Mode.FrameBuffer;
    FillChar(ptr^, width - partialWidth, ForeColor);
  end
  else
    FillChar(ptr^, width, ForeColor);
end;

procedure TSVgaDriver.VLine(x, y, height: integer);
begin
end;

procedure TSVgaDriver.FillRect(rect: TRect);
var
  index: word;
begin
  for index := rect.Y to rect.Bottom do begin
    HLine(rect.X, index, rect.Width);
  end;
end;

procedure TSvgaDriver.DrawImage(x, y, width, height: integer; image: PByte);
var
  xIndex, yIndex, sx, sy: integer;
  pixel: PByte;
  offset: longint;
  ptr: PByte;
begin
  pixel := image;
  for yIndex := 0 to height - 1 do begin
    sy := y + yIndex;
    sx := x;
    if (sy > Mode.MaxY) then break;
    if (sy < 0) then continue;
    for xIndex := 0 to width - 1 do
    begin
      if (sx > Mode.MaxX) then begin
        Inc(pixel, width - xIndex);
        break;
      end;
      if (pixel^ <> TransparentColor) and (sx > 0) then begin
        offset := sx + longint(sy) * Mode.Pitch;
        ptr := Mode.FrameBuffer;
        Inc(ptr, offset and $FFFF);
        SwitchBank(offset shr 16);
        ptr^ := pixel^;
      end;
      Inc(pixel);
      Inc(sx);
    end;
  end;
end;

procedure TSvgaDriver.GetImage(var buffer: PByte; rect: TRect);
var
  xIndex, yIndex, maxX, maxY: integer;
  offset: longint;
  dest, pixel: PByte;
  pitch: word;
begin
  dest := buffer;
  FillChar(buffer^, rect.Width * rect.Height, 0);
  pitch := Mode.Pitch;
  maxX := Mode.MaxX;
  maxY := Mode.MaxY;
  for yIndex := rect.Y to rect.Bottom do begin
    if (yIndex > maxY) then break;
    if (yIndex < 0) then continue;
    for xIndex := rect.X to rect.Right do begin
      if (xIndex > maxX) then begin
        Inc(dest);
        continue;
      end;
      if (xIndex > 0) then begin
        offset := xIndex + longint(yIndex) * pitch;
        pixel := Mode.FrameBuffer;
        Inc(pixel, offset and $FFFF);
        SwitchBank(offset shr 16);
        dest^ := pixel^;
      end;
      Inc(dest);
    end;
  end;
end;

destructor TSVgaDriver.Done;
begin
  TGraphicsDriver.Done;
end;

begin
end.