{$I COMPILER.TXT}
unit TextIni;

interface

uses
 Objects,
 TextDrv,
 DirTxDrv,
 SVgaText,
 CrtTxDrv;

type
  TTextDrivers =
  (
    tdDirect,
    tdAnsi,
    tdCrt,
    tdSvgaText
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
      TDirectTextDriver(driver).CreateId('Direct Text Driver');
    end;
    tdSvgaText: begin
      TSvgaTextDriver(driver).CreateId('SVGA Text Driver');
    end;
    tdAnsi: begin
    end;
    tdCrt: begin
      TCrtTextDriver(driver).CreateId('Crt Text Driver');
    end;
  end;
end;

end.
