{$IFDEF debug}
  {$A+,B-,D+,F+,G+,I+,L+,N+,P+,Q+,R+,S+,V+,X+,Y+}
{$ELSE}
  {$A+,B-,D-,F+,G+,I+,L-,N+,P+,Q-,R-,S-,V+,X+,Y-}
{$ENDIF}
unit GraphDrv;

interface

uses
  Objects,
  Utils,
  Drawing,
  WideStr,
  Streams;

const
  MaxIntensity = 18;
  Intensity50 = MaxIntensity div 2;
  Intensity25 = 4;
  Intensity75 = 14;
  InterfaceReservedMem = 65536;

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
  TGraphicsDriver = object(TObject)
  private
    _viewPort: TRect;
  public
    Modes: TGraphicsModeList;
    Mode: TGraphicsMode;
    ForeColor: byte;
    BackColor: byte;
    xPos, yPos: integer;
    Error: TError;
    function GetPixel(x, y: integer): byte; virtual;
    function GetColor(color: TStandardColor; intensity: byte): byte;
    procedure SetMode(newMode: TGraphicsMode); virtual;
    procedure SetPixel(x, y: integer); virtual;
    procedure GetViewPort(var rect: TRect); virtual;
    procedure SetViewPort(rect: TRect); virtual;
    procedure MoveTo(x, y: integer); virtual;
    procedure LineTo(x, y: integer); virtual;
    procedure Line(x1, y1, x2, y2: integer); virtual;
    procedure HLine(x, y, width: integer); virtual;
    procedure VLine(x, y, height: integer); virtual;
    procedure Rectangle(x1, y1, x2, y2: integer); virtual;
    procedure FillRect(rect: TRect); virtual;
    procedure DrawImage(x, y: integer; image: PByte); virtual;
    procedure DrawText(x, y: integer; text: string); virtual;
    procedure DrawTextW(x, y: integer; text: TWideString); virtual;
    procedure SetStandardPalette; virtual;
    procedure Init; virtual;
    destructor Done; virtual;
  end;

implementation

procedure TGraphicsDriver.Init;
begin
  TObject.Init;
  TypeName := 'TGraphicsDriver';
  ClearError(Error);
  Modes.Create('GraphicsModes');
  Mode.CreateEmpty;
  _viewPort.CreateEmpty;
  ForeColor := 0;
  BackColor := 0;
  xPos := 0;
  yPos := 0;
end;

procedure TGraphicsDriver.GetViewPort(var rect: TRect);
begin
  rect := _viewPort;
end;

procedure TGraphicsDriver.SetViewPort(rect: TRect);
begin
  _viewPort := rect;
end;

function TGraphicsDriver.GetPixel(x, y: integer): byte;
begin
end;

procedure TGraphicsDriver.SetMode(newMode: TGraphicsMode);
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

procedure TGraphicsDriver.DrawImage(x, y: integer; image: PByte);
begin
end;

procedure TGraphicsDriver.DrawText(x, y: integer; text: string);
begin
end;

procedure TGraphicsDriver.DrawTextW(x, y: integer; text: TWideString);
begin
end;

procedure TGraphicsDriver.SetStandardPalette;
begin
end;

destructor TGraphicsDriver.Done;
begin
end;

function TGraphicsDriver.GetColor(color: TStandardColor; intensity: byte): byte;
begin
  if (color = scBlack) then
  begin
    GetColor := 0;
    exit;
  end;
  GetColor := 21 + ord(color) * 17 + intensity;
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

end.