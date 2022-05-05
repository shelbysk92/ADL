unit TextDrv;

interface

uses
  Objects,
  Collects,
  Consts,
  Utils,
  Drawing,
  GraphDrv,
  WideStr;

type
  TTextChar = record
    Character: char;
    Attributes: byte;
  end;
  TLineStyle = (
    lsSingle,
    lsDouble
  );
  PTextState = ^TTextState;
  TTextState = object(TObject)
  public
    ForeColor, BackColor: byte;
    Blink: boolean;
    X, Y: byte;
    Attributes: byte;
    IsCursorOn: boolean;
    procedure Init; virtual;
  end;
  PTextMode = ^TTextMode;
  TTextMode = Object(TObject)
  private
  public
    Width, Height, MaxX, MaxY: integer;
    Name: string50;
    AdditionalData: integer;
    Description: string;
    HelpText: string;
    procedure Init; virtual;
    constructor CreateEmpty;
  end;
  PTextModeList = ^TTextModeList;
  TTextModeList = object(TObjectList)
  private
  public
    function GetItem(index: integer): PTextMode;
    function IndexOf(item: PTextMode): integer;
    function Add(item: PTextMode): integer;
    procedure Insert(index: integer; item: PTextMode);
  end;
  PTextDriver = ^TTextDriver;
  TTextDriver = Object(TObject)
  public
    StateStack: PStack;
    Mode: PTextMode;
    Modes: PTextModeList;
    Error: TError;
    State: PTextState;
    BppMode: byte;
    procedure PushState; virtual;
    procedure PopState; virtual;
    procedure Write(const txt: string); virtual;
    procedure WriteWide(txt: TWideString); virtual;
    procedure SetForeColor(color: byte); virtual;
    procedure SetBackColor(color: byte); virtual;
    procedure SetBlink(doBlink: boolean); virtual;
    procedure SetXY(newX, newY: byte); virtual;
    procedure CursorOn; virtual;
    procedure CursorOff; virtual;
    procedure Init; virtual;
    procedure SetMode(newMode: PTextMode); virtual;
    procedure HLine(x1, y1, width: byte; lineStyle: TLineStyle); virtual;
    procedure VLine(x1, y1, height: byte; lineStyle: TLineStyle); virtual;
    procedure Box(rect: TRect; style: TLineStyle); virtual;
    procedure FillRect(rect: TRect); virtual;
    procedure ClrScr; virtual;
    function ForeColor: byte; virtual;
    function BackColor: byte; virtual;
    destructor Done; virtual;
  end;

var
  TextDriver: PTextDriver;

implementation

procedure TTextState.Init;
begin
  ForeColor := 0;
  BackColor := 0;
  X := 0;
  Y := 0;
  Blink := false;
  Attributes := 0;
  IsCursorOn := true;
end;

procedure TTextMode.Init;
begin
  TObject.Init;
  TypeName := 'TTextMode';
  Width := 0;
  Height := 0;
  MaxX := 0;
  MaxY := 0;
  Name := '';
  AdditionalData := 0;
  Description := '';
  HelpText := '';
end;

constructor TTextMode.CreateEmpty;
begin
  Id := '';
  Init;
end;

function TTextModeList.GetItem(index: integer): PTextMode;
begin
  GetItem := pointer(TObjectList.GetItem(index));
end;

function TTextModeList.IndexOf(item: PTextMode): integer;
begin
  IndexOf := TObjectList.IndexOf(item);
end;

function TTextModeList.Add(item: PTextMode): integer;
begin
  Add := TObjectList.Add(item);
end;

procedure TTextModeList.Insert(index: integer; item: PTextMode);
begin
  TObjectList.Insert(index, item);
end;

procedure TTextDriver.PushState;
var
  newState: PTextState;
begin
  newState := New(PTextState, Create);
  newState^ := State^;
  StateStack^.Push(newState);
end;

procedure TTextDriver.PopState;
var
  oldState: PTextState;
begin
  oldState := PTextState(StateStack^.Pop);
  if (oldState = nil) then exit;
  State^ := oldState^;
  Dispose(oldState, Done);
  if (State^.IsCursorOn) then CursorOn
  else CursorOff;
  SetXY(State^.X, State^.Y);
end;

procedure TTextDriver.SetXY(newX, newY: byte);
begin
  State^.X := newX;
  State^.Y := newY;
end;

procedure TTextDriver.SetMode(newMode: PTextMode);
begin
end;

procedure TTextDriver.Write(const txt: string);
begin
end;

procedure TTextDriver.WriteWide(txt: TWideString);
begin
end;

procedure TTextDriver.SetForeColor(color: byte);
begin
  State^.ForeColor := color;
end;

procedure TTextDriver.SetBlink(doBlink: boolean);
begin
  State^.Blink := doBlink;
end;

procedure TTextDriver.SetBackColor(color: byte);
begin
  State^.BackColor := color;
end;

procedure TTextDriver.CursorOn;
begin
  State^.IsCursorOn := true;
end;

procedure TTextDriver.CursorOff;
begin
  State^.IsCursorOn := false;
end;

procedure TTextDriver.Init;
begin
  Modes := New(PTextModeList, Create);
  State := New(PTextState, Create);
  StateStack := New(PStack, Create);
  Mode := nil;
  ClearError(Error);
  BppMode := 4;
end;

destructor TTextDriver.Done;
begin
  Dispose(Modes, Done);
  Dispose(State, Done);
  Dispose(StateStack, Done);
  TObject.Done;
end;

procedure TTextDriver.HLine(x1, y1, width: byte; lineStyle: TLineStyle);
begin
end;

procedure TTextDriver.VLine(x1, y1, height: byte; lineStyle: TLineStyle);
begin
end;

procedure TTextDriver.Box(rect: TRect; style: TLineStyle);
begin
end;

procedure TTextDriver.ClrScr;
begin
end;

procedure TTextDriver.FillRect(rect: TRect);
begin
end;

function TTextDriver.ForeColor: byte;
begin
  ForeColor := State^.ForeColor;
end;

function TTextDriver.BackColor: byte;
begin
  BackColor := State^.BackColor;
end;

end.