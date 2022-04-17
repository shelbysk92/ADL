{$I Compiler.inc}
unit TextIni;

interface

uses
 Objects,
 TextDrv,
 DirTxDrv,
 CrtTxDrv;

type
  TTextDrivers =
  (
    tdDirect,
    tdAnsi,
    tdCrt
  );
  PTextDriverFactory = ^TTextDriverFactory;
  TTextDriverFactory = object(TBaseObject)
  public
    procedure Init; virtual;
    procedure CreateTextDriver(driverId: TTextDrivers; var driver);
  end;

implementation

procedure TTextDriverFactory.Init;
begin
end;

procedure TTextDriverFactory.CreateTextDriver(driverId: TTextDrivers; var driver);
begin
  case driverId of
    tdDirect: begin
      TDirectTextDriver(driver).Create('VGA Text Driver');
    end;
    tdAnsi: begin
    end;
    tdCrt: begin
      TCrtTextDriver(driver).Create('Crt Text Driver');
    end;
  end;
end;

end.
