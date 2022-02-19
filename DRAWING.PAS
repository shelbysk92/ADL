unit Drawing;

interface

uses
  Objects,
  Utils;

type
  TRect = object(TBaseObject)
  public
    X, Y, Width, Height: longint;
    constructor Create(newX, newY, newWidth, newHeight: longint);
    constructor CreateCoords(newX, newY, newRight, newBottom: longint);
    constructor CreateRect(newRect: TRect);
    constructor CreateEmpty;
    procedure SetDims(newX, newY, newWidth, newHeight: longint); virtual;
    procedure SetCoords(newX, newY, newRight, newBottom: longint); virtual;
    procedure SetRect(newRect: TRect); virtual;
    procedure SetRight(newRight: integer); virtual;
    procedure SetBottom(newBottom: integer); virtual;
    procedure Translate(dL, dT: longint); virtual;
    procedure Grow(dW, dH: integer); virtual;
    procedure Intersection(rect: TRect; var result: TRect); virtual;
    function Right: integer; virtual;
    function Bottom: integer; virtual;
    function IntersectPoint(pX, pY: longint): boolean; virtual;
    function IntersectRect(rect: TRect): boolean; virtual;
  end;

implementation

constructor TRect.CreateRect(newRect: TRect);
begin
  SetRect(newRect);
end;

constructor TRect.Create(newX, newY, newWidth, newHeight: longint);
begin
  SetDims(newX, newY, newWidth, newHeight);
end;

constructor TRect.CreateCoords(newX, newY, newRight, newBottom: longint);
begin
  SetCoords(newX, newY, newRight, newBottom);
end;

constructor TRect.CreateEmpty;
begin
  X := 0;
  Y := 0;
  Width := 0;
  Height := 0;
end;

procedure TRect.SetRight(newRight: integer);
begin
  Width := newRight - X + 1;
end;

procedure TRect.SetBottom(newBottom: integer);
begin
  Height := newBottom - Y + 1;
end;

procedure TRect.Translate(dL, dT: longint);
begin
  Inc(X, dL);
  Inc(Y, dT);
end;

procedure TRect.SetRect(newRect: TRect);
begin
  X := newRect.X;
  Y := newRect.Y;
  Width := newRect.Width;
  Height := newRect.Height
end;

procedure TRect.SetDims(newX, newY, newWidth, newHeight: longint);
begin
  X := newX;
  Y := newY;
  Width := newWidth;
  Height := newHeight;
end;

procedure TRect.SetCoords(newX, newY, newRight, newBottom: longint);
begin
  X := newX;
  Y := newY;
  Width := newRight - newX + 1;
  Height := newBottom - newY + 1;
end;

procedure TRect.Grow(dW, dH: integer);
begin
  Inc(Width, dW);
  Inc(Height, dH);
end;

function TRect.Right: integer;
begin
  Right := X + Width - 1;
end;

function TRect.Bottom: integer;
begin
  Bottom := Y + Height - 1;
end;

function TRect.IntersectPoint(pX, pY: longint): boolean;
begin
  IntersectPoint :=
    (pX >= X) and
    (pY >= Y) and
    (pX <= Right) and
    (pY <= Bottom);
end;

function TRect.IntersectRect(rect: TRect): boolean;
begin
  IntersectRect :=
    (X >= rect.X) and
    (X <= rect.Right) and
    (Y >= rect.Y) and
    (Y <= rect.Bottom);
end;

procedure TRect.Intersection(rect: TRect; var result: TRect);
begin
  if (not IntersectRect(rect)) then exit;
  result.CreateCoords(MaxL(X, rect.X), MaxL(Y, rect.Y), MinL(Right, rect.Right), MinL(Bottom, rect.Bottom));
end;

end.