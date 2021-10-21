unit SVgaDrv;

interface

uses
  Objects,
  GraphDrv,
  Utils,
  WideStr,
  Drawing;

type
  PSVgaDriver = ^TSVgaDriver;
  TSVgaDriver = object(TGraphicsDriver)
  private
    _viewPort: TRect;
    _sVgaDriver: integer;
  public
    function GetPixel(x, y: integer): byte; virtual;
    procedure SetSVgaPalette(palette: TRgbPalette);
    procedure InitBgiDriver(var driver: integer; bgiMode: integer);
    procedure RegisterBgiDriver(newMode: integer);
    procedure SetFillSolid(color: byte);  public
    procedure SetMode(newMode: TGraphicsMode); virtual;
    procedure SetPixel(x, y: integer); virtual;
    procedure GetViewPort(var rect: TRect); virtual;
    procedure SetViewPort(rect: TRect); virtual;
    procedure DrawText(x, y: integer; text: string); virtual;
    procedure DrawTextW(x, y: integer; text: TWideString); virtual;
    procedure MoveTo(x, y: integer); virtual;
    procedure LineTo(x, y: integer); virtual;
    procedure Line(x1, y1, x2, y2: integer); virtual;
    procedure Rectangle(x1, y1, x2, y2: integer); virtual;
    procedure HLine(x, y, width: integer); virtual;
    procedure VLine(x, y, height: integer); virtual;
    procedure FillRect(rect: TRect); virtual;
    procedure DrawImage(x, y: integer; image: PByte); virtual;
    procedure SetStandardPalette; virtual;
    procedure Init; virtual;
    destructor Done; virtual;
  end;

implementation

uses
  Graph,
  Globals,
  Dos;

const
  SVga320x200x256 = 0;
  SVga640x400x256 = 1;
  SVga640x480x256 = 2;
  SVga800x600x256 = 3;
  SVga1024x768x256 = 4;
  SVga640x350x256 = 5;
  SVga1280x1024x256 = 6;

var
  _solidPattern: FillPatternType;
  _selectedMode: integer;

procedure TSVgaDriver.Init;
var
  newMode: PGraphicsMode;
begin
  TGraphicsDriver.Init;
  TypeName := 'TSVgaDriver';
  SVgaDriver := 0;
  FillChar(_solidPattern, SizeOf(_solidPattern), $FF);

  newMode := New(PGraphicsMode, Create('SVGA320x200x256'));
  with newMode^ do
  begin
    AdditionalData := SVga320x200x256;
    Description := 'SVGA 320x200 256-Color';
    Width := 320;
    Height := 200;
    MaxX := 319;
    MaxY := 199;
    Bpp := 8;
    HelpText := 'Requires a VESA compliant Super VGA card.'
  end;
  Modes.Add(newMode);

  newMode := New(PGraphicsMode, Create('SVGA640x400x256'));
  with newMode^ do
  begin
    AdditionalData := SVga640x400x256;
    Description := 'SVGA 640x400 256-Color';
    Width := 640;
    Height := 400;
    MaxX := 639;
    MaxY := 399;
    Bpp := 8;
    HelpText := 'Requires a VESA compliant Super VGA card.'
  end;
  Modes.Add(newMode);

  newMode := New(PGraphicsMode, Create('SVGA640x480x256'));
  with newMode^ do
  begin
    AdditionalData := SVga640x480x256;
    Description := 'SVGA 640x480 256-Color';
    Width := 640;
    Height := 480;
    MaxX := 639;
    MaxY := 479;
    Bpp := 8;
    HelpText := 'Requires a VESA compliant Super VGA card.'
  end;
  Modes.Add(newMode);

  newMode := New(PGraphicsMode, Create('SVGA800x600x256'));
  with newMode^ do
  begin
    AdditionalData := SVga800x600x256;
    Description := 'SVGA 800x600 256-Color';
    Width := 800;
    Height := 600;
    MaxX := 799;
    MaxY := 599;
    Bpp := 8;
    HelpText := 'Requires a VESA compliant Super VGA card.'
  end;
  Modes.Add(newMode);

  newMode := New(PGraphicsMode, Create('SVGA1024x768x256'));
  with newMode^ do
  begin
    AdditionalData := SVga1024x768x256;
    Description := 'SVGA 1024x768 256-Color';
    Width := 1024;
    Height := 768;
    MaxX := 1023;
    MaxY := 767;
    Bpp := 8;
    HelpText := 'Requires a VESA compliant Super VGA card.'
  end;
  Modes.Add(newMode);

  newMode := New(PGraphicsMode, Create('SVGA640x350x256'));
  with newMode^ do
  begin
    AdditionalData := SVga640x350x256;
    Description := 'SVGA 640x350 256-Color';
    Width := 640;
    Height := 350;
    MaxX := 639;
    MaxY := 349;
    Bpp := 8;
    HelpText := 'Requires a VESA compliant Super VGA card.'
  end;
  Modes.Add(newMode);

  newMode := New(PGraphicsMode, Create('SVga640x350x256'));
  with newMode^ do
  begin
    AdditionalData := SVga640x350x256;
    Description := 'SVGA 640x350 256-Color';
    Width := 640;
    Height := 350;
    MaxX := 639;
    MaxY := 349;
    Bpp := 8;
    HelpText := 'Requires a VESA compliant Super VGA card.'
  end;
  Modes.Add(newMode);

  newMode := New(PGraphicsMode, Create('SVga1280x1024x256'));
  with newMode^ do
  begin
    AdditionalData := SVga1280x1024x256;
    Description := 'SVGA 1280x1024 256-Color';
    Width := 1280;
    Height := 1024;
    MaxX := 1279;
    MaxY := 1023;
    Bpp := 8;
    HelpText := 'Requires a VESA compliant Super VGA card.'
  end;
  Modes.Add(newMode);

end;

procedure TSVgaDriver.GetViewPort(var rect: TRect);
begin
  TGraphicsDriver.GetViewPort(rect);
end;

procedure TSVgaDriver.SetViewPort(rect: TRect);
var
  right, bottom, x, y, width, height: integer;
begin
  TGraphicsDriver.SetViewPort(rect);
  right := rect.Right;
  bottom := rect.bottom;
  x := rect.X;
  y := rect.Y;
  width := rect.Width;
  height := rect.height;
  Graph.SetViewPort(rect.X, rect.Y, rect.Right, rect.Bottom, true);
end;

function TSVgaDriver.GetPixel(x, y: integer): byte;
begin
end;

procedure TSVgaDriver.SetMode(newMode: TGraphicsMode);
var
  selectedMode: integer;
  rect: TRect;
begin
  RegisterBgiDriver(newMode.AdditionalData);
  InitBgiDriver(SVgaDriver, newMode.AdditionalData);
  if (Error.ErrorCode <> ecNone) then exit;
  Mode := newMode;
  rect.Create(0, 0, mode.Width, mode.Height);
  SetViewPort(rect);
  SetTextStyle(DefaultFont, HorizDir, 1);
end;

procedure TSVgaDriver.SetPixel(x, y: integer);
begin
end;

procedure TSVgaDriver.DrawText(x, y: integer; text: string);
begin
  SetColor(ForeColor);
  OutTextXY(x, y, text);
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
begin
  SetColor(ForeColor);
  SetLineStyle(SolidLn, 0, NormWidth);
  Graph.MoveTo(x, y);
  Graph.LineTo(x + width - 1, y);
end;

procedure TSVgaDriver.VLine(x, y, height: integer);
begin
end;

procedure TSVgaDriver.FillRect(rect: TRect);
begin
  SetColor(ForeColor);
  SetBkColor(BackColor);
  SetFillStyle(SolidFill, BackColor);
  SetFillPattern(_solidPattern, BackColor);
  Bar(rect.X, rect.Y, rect.Right, rect.Bottom);
end;

procedure TSVgaDriver.DrawImage(x, y: integer; image: PByte);
begin
end;

destructor TSVgaDriver.Done;
begin
  CloseGraph;
end;

procedure TSVgaDriver.SetSVgaPalette(palette: TRgbPalette);
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


procedure TSVgaDriver.SetStandardPalette;
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
  SetSvgaPalette(palette);
end;

procedure TSVgaDriver.InitBgiDriver(var driver: integer; bgiMode: integer);
var
  result: integer;
begin
  InitGraph(driver, bgiMode, AppDirectory + 'drivers\');
  result := GraphResult;
  if (result and $80 = $80) then
    result := result or $FF00;
  if (result <> 0) then
  begin
    CreateError(Error, ecGraphicsDriverError, esFatal);
    exit;
  end;
  SetStandardPalette;
end;

function DetectVga256: integer;
var
  mode: integer;
  DetectedDriver: integer;
begin
  DetectGraph(DetectedDriver, Mode);
  if (DetectedDriver = VGA) or (DetectedDriver = MCGA) then
    DetectVga256 := _selectedMode
  else
    DetectVga256 := grError;
end;

procedure TSVgaDriver.RegisterBgiDriver(newMode: integer);
begin
  _selectedMode := newMode;
  SVgaDriver := InstallUserDriver('SVGA256', @DetectVga256);
end;

procedure TSVgaDriver.SetFillSolid(color: byte);
begin
  SetFillStyle(SolidFill, color);
  SetFillPattern(_solidPattern, color);
end;

begin
end.