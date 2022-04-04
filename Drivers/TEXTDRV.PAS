unit TextDrv;

interface

uses
  Objects,
  Collects,
  Consts,
  Utils,
  WideStr;

type
  TLineStyle =
  (
    lsSingle,
    lsDouble
  );
  PTextState = ^TTextState;
  TTextState = object(TObject)
  public
    ForeColor, BackColor: byte;
    X, Y: byte;
    procedure Init; virtual;
    procedure Assign(state: TTextState); virtual;
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
    procedure Assign(mode: TTextMode); virtual;
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
  private
    _state: TTextState;
    _stateStack: PStack;
  public
    Mode: TTextMode;
    Modes: TTextModeList;
    Error: TError;
    procedure PushState; virtual;
    procedure PopState; virtual;
    procedure WriteText(const txt: string); virtual;
    procedure WriteTextLn(const txt: string); virtual;
    procedure WriteWideText(txt: TWideString); virtual;
    procedure WriteWideTextLn(txt: TWideString); virtual;
    procedure SetForeColor(color: byte); virtual;
    procedure SetBackColor(color: byte); virtual;
    procedure SetXY(newX, newY: byte); virtual;
    procedure Init; virtual;
    procedure SetMode(newMode: TTextMode); virtual;
    procedure HLine(x1, y1, width: byte; lineStyle: TLineStyle); virtual;
    procedure VLine(x1, y1, width: byte; lineStyle: TLineStyle); virtual;
    procedure ClrScr; virtual;
    function ForeColor: byte; virtual;
    function BackColor: byte; virtual;
    destructor Done; virtual;
  end;

var
  Txt: PTextDriver;

implementation

procedure TTextState.Init;
begin
  ForeColor := 0;
  BackColor := 0;
  X := 0;
  Y := 0;
end;

procedure TTextState.Assign(state: TTextState);
begin
  ForeColor := state.ForeColor;
  BackColor := state.BackColor;
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

procedure TTextMode.Assign(mode: TTextMode);
begin
    Width := mode.Width;
    Height := mode.Height;
    MaxX := mode.MaxX;
    MaxY := mode.MaxY;
    Name := mode.Name;
    AdditionalData := mode.AdditionalData;
    Description := mode.Description;
    HelpText := mode.HelpText;
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
  state: PTextState;
begin
  state := New(PTextState, Create(''));
  state^.Assign(_state);
  _stateStack^.Push(state);
end;

procedure TTextDriver.PopState;
var
  state: PTextState;
begin
  state := PTextState(_stateStack^.Pop);
  if (state = nil) then exit;
  _state.Assign(state^);
  Dispose(state, Done);
end;

procedure TTextDriver.SetXY(newX, newY: byte);
begin
  _state.X := newX;
  _state.Y := newY;
end;

procedure TTextDriver.SetMode(newMode: TTextMode);
begin
end;

procedure TTextDriver.WriteText(const txt: string);
begin
end;

procedure TTextDriver.WriteTextLn(const txt: string);
begin
end;

procedure TTextDriver.WriteWideText(txt: TWideString);
begin
end;

procedure TTextDriver.WriteWideTextLn(txt: TWideString);
begin
end;

procedure TTextDriver.SetForeColor(color: byte);
begin
  _state.ForeColor := color;
end;

procedure TTextDriver.SetBackColor(color: byte);
begin
  _state.BackColor := color;
end;

procedure TTextDriver.Init;
begin
  Modes.Create('TextDrvModeList');
  Mode.CreateEmpty;
  _stateStack := New(PStack, Create('TextStateStack'));
end;

destructor TTextDriver.Done;
begin
  Dispose(_stateStack, Done);
  Modes.Done;
end;

procedure TTextDriver.HLine(x1, y1, width: byte; lineStyle: TLineStyle);
begin
end;

procedure TTextDriver.VLine(x1, y1, width: byte; lineStyle: TLineStyle);
begin
end;

procedure TTextDriver.ClrScr;
begin
end;

function TTextDriver.ForeColor: byte;
begin
  ForeColor := _state.ForeColor;
end;

function TTextDriver.BackColor: byte;
begin
  BackColor := _state.BackColor;
end;

end.