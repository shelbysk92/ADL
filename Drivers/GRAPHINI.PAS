{$I COMPILER.TXT}
unit GraphIni;

interface

uses
 Objects,
 SvgaDrv,
 GraphDrv;

type
  TGraphDrivers =
  (
    gdVga256,
    gdSVga256
  );
  PGraphicsFactory = ^TGraphicsFactory;
  TGraphicsFactory = object(TBaseObject)
  public
    procedure Init; virtual;
    procedure CreateGraphicsDriver(driverId: TGraphDrivers; var driver);
  end;

implementation

procedure TGraphicsFactory.Init;
begin
end;

procedure TGraphicsFactory.CreateGraphicsDriver(driverId: TGraphDrivers; var driver);
begin
  case driverId of
    gdVga256:
    begin
    end;
    gdSVga256:
    begin
      TSvgaDriver(driver).Create;
    end;
  end;
end;

end.
