unit Drawing;

interface

uses
  Utils;

type
  TRectData = record
    X, Y, Width, Height: longint;
  end;
  TRect = object
    Prop : TRectData;
    constructor Create(newX, newY, newWidth, newHeight: longint);
    constructor CreateCoords(newX, newY, newRight, newBottom: longint);
    constructor Assign(newRect: TRect);
    constructor CreateEmpty;
    procedure GetRect(var newRect: TRect); virtual;
    procedure SetX(newX: integer); virtual;
    procedure SetY(newY: integer); virtual;
    procedure SetWidth(newWidth: integer); virtual;
    procedure SetHeight(newHeight: integer); virtual;
    procedure SetRight(newRight: integer); virtual;
    procedure SetBottom(newBottom: integer); virtual;
    procedure Translate(dL, dT: longint); virtual;
    procedure SetRect(newX, newY, newWidth, newHeight: longint); virtual;
    procedure SetRectCoords(newX, newY, newRight, newBottom: longint); virtual;
    procedure Grow(dW, dH: integer); virtual;
    procedure Intersection(rect: TRect; var result: TRect); virtual;
    function X: integer; virtual;
    function Y: integer; virtual;
    function Width: integer; virtual;
    function Height: integer; virtual;
    function Right: integer; virtual;
    function Bottom: integer; virtual;
    function IntersectPoint(pX, pY: longint): boolean; virtual;
    function IntersectRect(rect: TRect): boolean; virtual;
  end;

implementation

constructor TRect.Create(newX, newY, newWidth, newHeight: longint);
begin
  SetRect(newX, newY, newWidth, newHeight);
end;

constructor TRect.CreateCoords(newX, newY, newRight, newBottom: longint);
begin
  SetRectCoords(newX, newY, newRight, newBottom);
end;

constructor TRect.Assign(newRect: TRect);
begin
  Prop.X := newRect.X;
  Prop.Y := newRect.Y;
  Prop.Width := newRect.Width;
  Prop.Height := newRect.Height;
end;

constructor TRect.CreateEmpty;
begin
  FillChar(Prop, SizeOf(Prop), 0);
end;

procedure TRect.GetRect(var newRect: TRect);
begin
  newRect.Assign(Self);
end;

procedure TRect.SetX(newX: integer);
begin
  Prop.X := newX;
end;

procedure TRect.SetY(newY: integer);
begin
  Prop.Y := newY;
end;

procedure TRect.SetWidth(newWidth: integer);
begin
  Prop.Width := newWidth;
end;

procedure TRect.SetHeight(newHeight: integer);
begin
  Prop.Height := newHeight;
end;

procedure TRect.SetRight(newRight: integer);
begin
  Prop.Width := newRight - Prop.X + 1;
end;

procedure TRect.SetBottom(newBottom: integer);
begin
  Prop.Height := newBottom - Prop.Y + 1;
end;

procedure TRect.Translate(dL, dT: longint);
begin
  Inc(Prop.X, dL);
  Inc(Prop.Y, dT);
end;

procedure TRect.SetRect(newX, newY, newWidth, newHeight: longint);
begin
  Prop.X := newX;
  Prop.Y := newY;
  Prop.Width := newWidth;
  Prop.Height := newHeight;
end;

procedure TRect.SetRectCoords(newX, newY, newRight, newBottom: longint);
begin
  Prop.X := newX;
  Prop.Y := newY;
  Prop.Width := newRight - newX + 1;
  Prop.Height := newBottom - newY + 1;
end;

procedure TRect.Grow(dW, dH: integer);
begin
  Inc(Prop.Width, dW);
  Inc(Prop.Height, dH);
end;

function TRect.X: integer;
begin
  X := Prop.X;
end;

function TRect.Y: integer;
begin
  Y := Prop.Y;
end;

function TRect.Width: integer;
begin
  Width := Prop.Width;
end;

function TRect.Height: integer;
begin
  Height := Prop.Height;
end;

function TRect.Right: integer;
begin
  Right := Prop.X + Prop.Width - 1;
end;

function TRect.Bottom: integer;
begin
  Bottom := Prop.Y + Prop.Height - 1;
end;

function TRect.IntersectPoint(pX, pY: longint): boolean;
begin
  IntersectPoint :=
    (pX >= Prop.X) and
    (pY >= Prop.Y) and
    (pX <= Right) and
    (pY <= Bottom);
end;

function TRect.IntersectRect(rect: TRect): boolean;
begin
  IntersectRect :=
    (Prop.X >= rect.Prop.X) and
    (Prop.X <= rect.Right) and
    (Prop.Y >= rect.Prop.Y) and
    (Prop.Y <= rect.Bottom);
end;

procedure TRect.Intersection(rect: TRect; var result: TRect);
begin
  if (not IntersectRect(rect)) then exit;
  result.CreateEmpty;
  result.Prop.X := MaxL(Prop.X, rect.Prop.X);
  result.Prop.Y := MaxL(Prop.Y, rect.Prop.Y);
  result.SetRight(MinL(Right, rect.Right));
  result.SetBottom(MinL(Bottom, rect.Bottom));
end;

end.