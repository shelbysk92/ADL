{$I Compiler.inc}
unit GraphDrv;

interface

uses
  Objects,
  Utils,
  Dos,
  Drawing,
  WideStr,
  Streams;

const
  MinIntensity = 1;
  MaxIntensity = 18;
  Intensity50 = 9;
  Intensity25 = 4;
  Intensity75 = 14;
  TransparentColor = 1;

type
  TStandardColor =
  (
    scWhite,
    scRed,
    scGreen,
    scBlue,
    scCyan,
    scYellow,
    scMagenta,
    scOrange,
    scChartreuse,
    scSpringGreen,
    scAzure,
    scViolet,
    scPink,
    scBlack
  );
  TColor = record
    Color: TStandardColor;
    Shade: byte;
  end;
  TRgbColor = record
    Red: byte;
    Green: byte;
    Blue: byte;
  end;
  TRgbPalette = array[byte] of TRgbColor;
  PGraphicsMode = ^TGraphicsMode;
  TGraphicsMode = object(TObject)
  public
    Width, Height: integer;
    MaxX, MaxY: integer;
    Bpp: byte;
    AdditionalData: integer;
    Description: string;
    HelpText: string;
    constructor CreateEmpty;
    constructor CreateAssign(mode:  TGraphicsMode);
    procedure Assign(mode: TGraphicsMode); virtual;
  end;
  PGraphicsModeList = ^TGraphicsModeList;
  TGraphicsModeList = object(TObjectList)
  public
    function GetItem(index: integer): PGraphicsMode;
    function IndexOf(item: PGraphicsMode): integer;
    function Add(item: PGraphicsMode): integer;
    procedure Insert(index: integer; item: PGraphicsMode);
  end;
  PGraphicsDriver = ^TGraphicsDriver;
  PFont = ^TFont;
  TFont = object(TObject)
  private
    _fontData: PByte;
    _maxWidth: integer;
  public
    Version: real;
    TransparentColor: byte;
    Transparent: boolean;
    Initialized: boolean;
    Height: integer;
    constructor Create(newId: string);
    constructor CreateAssign(font: TFont);
    destructor Done; virtual;
    procedure Assign(font: TFont); virtual;
    procedure Init; virtual;
    procedure ReadFromStream(stream: TStream; var error: TError); virtual;
    procedure WriteToStream(stream: TStream; var error: TError); virtual;
    function CharWidth(ch: char): integer; virtual;
    function TextWidth(text: string): integer; virtual;
    function TextWidthW(text: TWideString): integer; virtual;
  end;
  PGraphicsSettings = ^TGraphicsSettings;
  TGraphicsSettings = object(TPersistent)
  private
  public
    ForeColor: byte;
    BackColor: byte;
    XPos, YPos: integer;
    procedure Init; virtual;
    procedure Assign(var source: TPersistent); virtual;
    procedure AssignTo(var dest: TPersistent); virtual;
  end;
  TGraphicsDriver = object(TObject)
  private
    _settings: PGraphicsSettings;
    _stateStack: TStack;
    _oldMode: byte;
  public
    Modes: TGraphicsModeList;
    Mode: PGraphicsMode;
    Error: TError;
    function GetPixel(x, y: integer): byte; virtual;
    function GetColor(color: TStandardColor; intensity: byte): byte; virtual;
    function ForeColor: byte; virtual;
    function BackColor: byte; virtual;
    function XPos: byte; virtual;
    function YPos: byte; virtual;
    function GetImage(rect: TRect): PByte; virtual;
    procedure SetForeColor(color: byte); virtual;
    procedure SetBackColor(color: byte); virtual;
    procedure SetMode(newMode: PGraphicsMode); virtual;
    procedure SetPixel(x, y: integer); virtual;
    procedure MoveTo(x, y: integer); virtual;
    procedure LineTo(x, y: integer); virtual;
    procedure Line(x1, y1, x2, y2: integer); virtual;
    procedure HLine(x, y, width: integer); virtual;
    procedure VLine(x, y, height: integer); virtual;
    procedure Rectangle(x1, y1, x2, y2: integer); virtual;
    procedure FillRect(rect: TRect); virtual;
    procedure DrawImage(sourceRect, destRect: TRect; image: PByte); virtual;
    procedure DrawText(x, y: integer; text: string); virtual;
    procedure DrawTextW(x, y: integer; text: TWideString); virtual;
    procedure SetStandardPalette; virtual;
    procedure SetRgbPalette(palette: TRgbPalette);
    procedure PushState; virtual;
    procedure PopState; virtual;
    procedure Init; virtual;
    destructor Done; virtual;
  end;

var
  Graphics: TGraphicsDriver;

implementation

procedure TGraphicsDriver.Init;
var
  oldMode: byte;
begin
  TObject.Init;
  TypeName := 'TGraphicsDriver';
  asm
    mov   al, 00h
    mov   ah, 0Fh
    int   10h
    mov   [oldMode], al
  end;
  _oldMode := oldMode;
  ClearError(Error);
  Modes.Create('GraphicsModes');
  Mode^.CreateEmpty;
  _settings := New(PGraphicsSettings, Create('GraphSettings'));
  _stateStack.Create('StateStack');
  MoveTo(0, 0);
end;

function TGraphicsDriver.ForeColor: byte;
begin
  ForeColor := _settings^.ForeColor;
end;

function TGraphicsDriver.BackColor: byte;
begin
  BackColor := _settings^.BackColor;
end;

function TGraphicsDriver.XPos: byte;
begin
  XPos := _settings^.XPos;
end;

function TGraphicsDriver.YPos: byte;
begin
  YPos := _settings^.YPos;
end;

procedure TGraphicsDriver.SetForeColor(color: byte);
begin
  _settings^.ForeColor := color;
end;

procedure TGraphicsDriver.SetBackColor(color: byte);
begin
  _settings^.BackColor := color;
end;

function TGraphicsDriver.GetPixel(x, y: integer): byte;
begin
end;

procedure TGraphicsDriver.SetMode(newMode: PGraphicsMode);
begin
end;

procedure TGraphicsDriver.SetPixel(x, y: integer);
begin
end;

procedure TGraphicsDriver.MoveTo(x, y: integer);
begin
end;

procedure TGraphicsDriver.LineTo(x, y: integer);
begin
end;

procedure TGraphicsDriver.Line(x1, y1, x2, y2: integer);
begin
end;

procedure TGraphicsDriver.Rectangle(x1, y1, x2, y2: integer);
begin
end;

procedure TGraphicsDriver.HLine(x, y, width: integer);
begin
end;

procedure TGraphicsDriver.VLine(x, y, height: integer);
begin
end;

procedure TGraphicsDriver.FillRect(rect: TRect);
begin
end;

procedure TGraphicsDriver.DrawImage(sourceRect, destRect: TRect; image: PByte);
begin
end;

function TGraphicsDriver.GetImage(rect: TRect): PByte;
begin
end;

procedure TGraphicsDriver.DrawText(x, y: integer; text: string);
begin
end;

procedure TGraphicsDriver.DrawTextW(x, y: integer; text: TWideString);
begin
end;

procedure TGraphicsDriver.SetStandardPalette;
var
  palette: TRgbPalette;
  colorIndex: TStandardColor;
  shadeIndex, shade: integer;
  paletteIndex: integer;
  index: integer;
begin
  for Index := 0 to 21 do
  begin
    palette[index].Red := 0;
    palette[index].Green := 0;
    palette[index].Blue := 0;
  end;
  paletteIndex := 22;

  for colorIndex := Low(TStandardColor) to High(TStandardColor) do
  begin
    for shadeIndex := 1 to 18 do
    begin
      shade := shadeIndex * 14;
      case colorIndex of
        scWhite:
        begin
          palette[paletteIndex].Red := shade;
          palette[paletteIndex].Green := shade;
          palette[paletteIndex].Blue := shade;
        end;
        scRed:
        begin
          palette[paletteIndex].Red := shade;
          palette[paletteIndex].Green := 0;
          palette[paletteIndex].Blue := 0;
        end;
        scGreen:
        begin
          palette[paletteIndex].Red := 0;
          palette[paletteIndex].Green := shade;
          palette[paletteIndex].Blue := 0;
        end;
        scBlue:
        begin
          palette[paletteIndex].Red := 0;
          palette[paletteIndex].Green := 0;
          palette[paletteIndex].Blue := shade;
        end;
        scYellow:
        begin
          palette[paletteIndex].Red := shade;
          palette[paletteIndex].Green := shade;
          palette[paletteIndex].Blue := 0;
        end;
        scMagenta:
        begin
          palette[paletteIndex].Red := shade;
          palette[paletteIndex].Green := 0;
          palette[paletteIndex].Blue := shade;
        end;
        scCyan:
        begin
          palette[paletteIndex].Red := 0;
          palette[paletteIndex].Green := shade;
          palette[paletteIndex].Blue := shade;
        end;
        scOrange:
        begin
          palette[paletteIndex].Red := shade;
          palette[paletteIndex].Green := shade div 2;
          palette[paletteIndex].Blue := 0;
        end;
        scChartreuse:
        begin
          palette[paletteIndex].Red := shade div 2;
          palette[paletteIndex].Green := shade;
          palette[paletteIndex].Blue := 0;
        end;
        scSpringGreen:
        begin
          palette[paletteIndex].Red := shade div 2;
          palette[paletteIndex].Green := shade;
          palette[paletteIndex].Blue := shade div 2;
        end;
        scAzure:
        begin
          palette[paletteIndex].Red := shade div 3;
          palette[paletteIndex].Green := shade div 3;
          palette[paletteIndex].Blue := shade;
        end;
        scViolet:
        begin
          palette[paletteIndex].Red := shade div 2;
          palette[paletteIndex].Green := 0;
          palette[paletteIndex].Blue := shade;
        end;
        scPink:
        begin
          palette[paletteIndex].Red := shade;
          palette[paletteIndex].Green := shade div 3;
          palette[paletteIndex].Blue := shade;
        end;
      end;
      Inc(paletteIndex);
    end;
  end;
  SetRgbPalette(palette);
end;

procedure TGraphicsDriver.SetRgbPalette(palette: TRgbPalette);
var
  reg: Registers;
  index: integer;
begin
  for index := 0 to 255 do
  begin
    with palette[index] do
    begin
      Red := Red shr 2;
      Green := Green shr 2;
      Blue := Blue shr 2;
    end;
  end;
  FillChar(reg, SizeOf(reg), 0);
  with reg do
  begin
    AX := $1012;
    BX := $0;
    CX := $FF;
    ES := Seg(palette);
    DX := Ofs(palette);
    Intr($10, reg);
  end;
end;

procedure TGraphicsDriver.PushState;
var
  settings: PGraphicsSettings;
begin
  settings := New(PGraphicsSettings, Create('StackSettings'));
  settings^.Assign(_settings^);
  _stateStack.Push(settings);
end;

procedure TGraphicsDriver.PopState;
var
  settings: PGraphicsSettings;
begin
  settings := PGraphicsSettings(_stateStack.Pop);
  if (settings = nil) then exit;
  _settings^.Assign(settings^);
  Dispose(settings, Done);
end;

destructor TGraphicsDriver.Done;
var
  oldMode: byte;
begin
  oldMode := _oldMode;
  asm
    mov ah, 00h
    mov al, [oldMode]
    int 10h
  end;
  _stateStack.Done;
  Dispose(_settings, Done);
end;

function TGraphicsDriver.GetColor(color: TStandardColor; intensity: byte): byte;
begin
  if (color = scBlack) then
  begin
    GetColor := 0;
    exit;
  end;
  GetColor := 21 + ord(color) * 18 + intensity;
end;

constructor TGraphicsMode.CreateEmpty;
begin
  Width := 0;
  Height := 0;
  MaxX := 0;
  MaxY := 0;
  Bpp := 0;
  AdditionalData := -1;
  HelpText := '';
end;

constructor TGraphicsMode.CreateAssign(mode: TGraphicsMode);
begin
  Assign(mode);
end;

procedure TGraphicsMode.Assign(mode: TGraphicsMode);
begin
  Width := mode.Width;
  Height := mode.Height;
  MaxX := mode.MaxX;
  MaxY := mode.MaxY;
  Bpp := mode.Bpp;
  Description := mode.Description;
  AdditionalData := mode.AdditionalData;
  HelpText := mode.HelpText;
end;

function TGraphicsModeList.GetItem(index: integer): PGraphicsMode;
begin
  GetItem := pointer(TObjectList.GetItem(index));
end;

function TGraphicsModeList.IndexOf(item: PGraphicsMode): integer;
begin
  IndexOf := TObjectList.IndexOf(item);
end;

function TGraphicsModeList.Add(item: PGraphicsMode): integer;
begin
  Add := TObjectList.Add(item);
end;

procedure TGraphicsModeList.Insert(index: integer; item: PGraphicsMode);
begin
  TObjectList.Insert(index, item);
end;

constructor TFont.Create(newId: string);
begin
  Id := newId;
  Init;
end;

constructor TFont.CreateAssign(font: TFont);
begin
end;

destructor TFont.Done;
begin
end;

procedure TFont.Assign(font: TFont);
begin
end;

procedure TFont.Init;
begin
  TObject.Init;
  TypeName := 'TFont';
  _fontData := nil;
  _maxWidth := 8;
  Version := 1.0;
  TransparentColor := 0;
  Transparent := true;
  Initialized := true;
  Height := 8;
end;

procedure TFont.ReadFromStream(stream: TStream; var error: TError);
begin
end;

procedure TFont.WriteToStream(stream: TStream; var error: TError);
begin
end;

function TFont.CharWidth(ch: char): integer;
begin
end;

function TFont.TextWidth(text: string): integer;
begin
  TextWidth := Length(text) * 8;
end;

function TFont.TextWidthW(text: TWideString): integer;
begin
  TextWidthW := text.Len * 8;
end;

procedure TGraphicsSettings.Init;
begin
  TPersistent.Init;
  TypeName := 'TGraphicsSettings';
  ForeColor := 0;
  BackColor := 0;
  XPos := 0;
  YPos := 0;
end;

procedure TGraphicsSettings.Assign(var source: TPersistent);
var
  settings: PGraphicsSettings;
begin
  settings := PGraphicsSettings(@source);
  ForeColor := settings^.ForeColor;
  BackColor := settings^.BackColor;
  XPos := settings^.XPos;
  YPos := settings^.YPos;
end;

procedure TGraphicsSettings.AssignTo(var dest: TPersistent);
var
  settings: PGraphicsSettings;
begin
  settings := PGraphicsSettings(@dest);
  settings^.ForeColor := ForeColor;
  settings^.BackColor := BackColor;
  settings^.XPos := XPos;
  settings^.YPos := YPos;
end;

end.