{$I compiler.inc}
unit SvgaText;

interface

uses
  Objects,
  GraphDrv,
  SVgaDrv,
  GraphIni,
  TextDrv,
  WideStr,
  Drawing,
  Utils,
  MouseDrv,
  Collects;

type
  PSvgaTextState = object(TTextState)
  private
  public
    GraphX, GraphY: integer;
  end;
  PSvgaTextDriver = ^TSvgaTextDriver;
  TSvgaTextDriver = Object(TTextDriver)
  private
  public
    procedure Write(const txt: string); virtual;
    procedure WriteWide(txt: TWideString); virtual;
    procedure SetXY(newX, newY: byte); virtual;
    procedure CursorOn; virtual;
    procedure CursorOff; virtual;
    procedure Init; virtual;
    procedure SetMode(newMode: TTextMode); virtual;
    procedure HLine(x1, y1, width: byte; lineStyle: TLineStyle); virtual;
    procedure VLine(x1, y1, height: byte; lineStyle: TLineStyle); virtual;
    procedure Box(rect: TRect; style: TLineStyle); virtual;
    procedure FillRect(rect: TRect); virtual;
    procedure ClrScr; virtual;
    destructor Done; virtual;
  end;

implementation

procedure TSvgaTextDriver.SetMode(newMode: TTextMode);
var
  graphMode: PGraphicsMode;
  modeIndex: integer;
begin
  graphMode := Graphics.Modes.GetItem(newMode.AdditionalData);
  if (graphMode = nil) then
  begin
    CreateError(Graphics.Error, ecGraphicsModeNotFound, esError);
    exit;
  end;
  Graphics.SetMode(graphMode);
  MouseDriver.SetMouseResolution(graphMode^.Width, graphMode^.Height);
end;


procedure TSvgaTextDriver.SetXY(newX, newY: byte);
begin
end;

procedure TSvgaTextDriver.Write(const txt: string);
begin
end;

procedure TSvgaTextDriver.WriteWide(txt: TWideString);
begin
end;

procedure TSvgaTextDriver.CursorOn;
begin
end;

procedure TSvgaTextDriver.CursorOff;
begin
end;

function Is16Color(item: pointer; var value): boolean; far;
begin
  Is16Color := PGraphicsMode(item)^.Bpp = 4;
end;

procedure TSvgaTextDriver.Init;
var
  factory: TGraphicsFactory;
  modeIndex: integer;
  graphicsModes: PGraphicsModeList;
  graphicsMode: PGraphicsMode;
  textMode: PTextMode;
  value: integer;
begin
  TTextDriver.Init;
  TypeName := 'TSvgaTextDriver';
  factory.CreateGraphicsDriver(gdSVga256, Graphics);
  graphicsModes := Graphics.Modes.Where(Is16Color, value);
  for modeIndex := 0 to graphicsModes^.Count - 1 do begin
    graphicsMode := graphicsModes^.GetItem(modeIndex);
    textMode := New(PTextMode, CreateEmpty);
    with textMode^ do begin
      Width := graphicsMode^.Width div 8;
      Height := graphicsMode^.Height div 16;
      MaxX := Width - 1;
      MaxY := Height - 1;
      Name := 'SVga Text ' + IntToStr(Width) + 'x' + IntToStr(Height);
      Id := 'SVgaText' + IntToStr(Width) + 'x' + IntToStr(Height);
      AdditionalData := modeIndex;
      Description := 'SVGA Text ' + IntToStr(Width) + 'x' + IntToStr(Height) +
        ' (SVGA ' + IntToStr(graphicsMode^.Width) + 'x' + IntToStr(graphicsMode^.Height) + ')';
      HelpText := 'Requires VESA compatible Super VGA card.';
    end;
    Modes.Add(textMode);
  end;
  Dispose(graphicsModes, Done);
end;

destructor TSvgaTextDriver.Done;
begin
  TSvgaTextDriver.Done;
end;

procedure TSvgaTextDriver.HLine(x1, y1, width: byte; lineStyle: TLineStyle);
begin
end;

procedure TSvgaTextDriver.VLine(x1, y1, height: byte; lineStyle: TLineStyle);
begin
end;

procedure TSvgaTextDriver.Box(rect: TRect; style: TLineStyle);
begin
end;

procedure TSvgaTextDriver.ClrScr;
begin
end;

procedure TSvgaTextDriver.FillRect(rect: TRect);
begin
end;

end.