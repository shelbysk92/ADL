unit ImgFile;

interface
uses
  VgaGraph,
  Utils;

const
  ImgFileVersion: real = 1.0;

type
  TCompressionType =
  (
    ctNone,
    ctDeflate
  );
  TImgFileHeader = packed record
    HeaderText: string[3];
    Version: real;
    Width: word;
    Height: word;
    Compression: TCompressionType;
    Palette: TVgaPalette;
    Reserved: array[0..255] of byte;
  end;

procedure CreateImgHeader
(
  var header: TImgFileHeader;
  imgWidth, imgHeight: word;
  compressionType: TCompressionType;
  vgaPalette: TVgaPalette
);
function LoadImage
(
  var dest: PByte;
  const filename: string;
  offset: longint;
  var header: TImgFileHeader;
  var error: TError
): boolean;

function LoadFont
(
  var font: PFont;
  const filename: string;
  var error: TError
): boolean;

function SaveFont
(
  font: PFont;
  const fileName: string;
  var error: TError
): boolean;

function SaveImage
(
  image: PByte;
  const filename: string;
  width: word;
  height: word;
  var error: TError
): boolean;

implementation

function LoadImage
(
  var dest: PByte;
  const filename: string;
  offset: longint;
  var header: TImgFileHeader;
  var error: TError
): boolean;
var
  workFile: file;
  result: integer;
begin
  FillChar(error, SizeOf(TError), 0);
  {$I-}
  Assign(workFile, filename);
  Reset(workFile, 1);
  result := IOResult;

  if (result <> 0) then
  begin
    CreateError(error, ecFileOpenError);
    LoadImage := false;
    exit;
  end;

  Seek(workFile, offset);

  BlockRead(workFile, header, SizeOf(header));
  if (result <> 0) then
  begin
    CreateError(error, ecFileReadError);
    LoadImage := false;
    Close(workFile);
    exit;
  end;
  if (header.HeaderText <> 'img') then
    begin
      CreateError(error, ecFileInvalid);
      LoadImage := false;
      Close(workFile);
      exit;
    end;

  if (header.Version > ImgFileVersion) then
  begin
    CreateError(error, ecFileVersionError);
    LoadImage := false;
    Close(workFile);
    exit;
  end;

  GetMem(dest, header.Width * header.Height);
  BlockRead(workFile, dest^, header.Width * header.Height);
  if (result <> 0) then
  begin
    CreateError(error, ecFileReadError);
    LoadImage := false;
    Close(workFile);
    exit;
  end;

  Close(workFile);
  {$I+}
end;

function SaveImage
(
  image: PByte;
  const filename: string;
  width: word;
  height: word;
  var error: TError
): boolean;
var
  workFile: file;
  header: TImgFileHeader;
begin
  CreateImgHeader(header, width, height, ctNone, VgaPalette);

  {$I-}
  Assign(workFile, fileName);
  Rewrite(workFile, 1);

  if (IOResult <> 0) then
  begin
    CreateError(error, ecFileCreateError);
    SaveImage := false;
  end;

  BlockWrite(workFile, header, SizeOf(header));
  BlockWrite(workFile, image^, height * width);

  if (IOResult <> 0) then
  begin
    CreateError(error, ecFileWriteError);
    SaveImage := false;
  end;

  {$I+}
end;

function SaveFont
(
  font: PFont;
  const filename: string;
  var error: TError
): boolean;
var
  workFile: file;
  result: integer;
  header: TImgFileHeader;
  fontHeader: string[3];
  width: word;
begin
  {$I-}
  FillChar(error, SizeOf(error), 0);
  Assign(workFile, fileName);
  Rewrite(workFile, 1);
  result := IOResult;
  if (result <> 0) then
  begin
    CreateError(error, ecFileCreateError);
    SaveFont := false;
    exit;
  end;
  if ((UpperCase(GetExtension(fileName)) = '.FNT') and (Font <> nil)) then
  begin
    CalculateFontWidths(font);
    fontHeader := 'fnt';
    BlockWrite(workFile, fontHeader, SizeOf(fontHeader));
    BlockWrite(workFile, font^, SizeOf(TFont));
  end;

  width := (font^.MaxCharWidth + 1) * 100;
  CreateImgHeader(header, width, Font^.Height, ctNone, VgaPalette);
  BlockWrite(workfile, header, SizeOf(header));
  BlockWrite(workFile, font^.Data^, font^.Height * width);

  result := IOResult;
  if (result <> 0) then
  begin
    CreateError(error, ecFileCreateError);
    SaveFont := false;
  end;
  Close(workFile);
  {I+}
end;

function LoadFont
(
  var font: PFont;
  const filename: string;
  var error: TError
): boolean;
var
  workFile: file;
  result: integer;
  fontHeader: string[3];
  header: TImgFileHeader;
  offset: longint;
begin
  {$I-}
  FillChar(error, SizeOf(TError), 0);
  if (font <> nil) then
  begin
    if (font^.Data <> nil) then
      FreeMem(font^.Data, font^.MaxCharWidth * font^.Height);
    FreeMem(font, SizeOf(TFont));
  end;
  GetMem(Font, SizeOf(TFont));
  Font^.Data := nil;
  offset := 0;

  Assign(workFile, filename);
  Reset(workFile, 1);
  result := IOResult;
  if (result <> 0) then
  begin
    CreateError(error, ecFileOpenError);
    LoadFont := false;
    exit;
  end;

  BlockRead(workFile, fontHeader, Sizeof(fontHeader));
  Inc(offset, SizeOf(fontHeader));
  if (fontHeader <> 'fnt') then
  begin
    CreateError(error, ecFileInvalid);
    LoadFont := false;
    Close(workFile);
    exit;
  end;
  BlockRead(workFile, font^, SizeOf(TFont));
  Inc(offset, SizeOf(TFont));
  GetMem(font^.Data, font^.Height + (font^.MaxCharWidth + 1) * 100);
  if (result <> 0) then
  begin
    CreateError(error, ecFileReadError);
    LoadFont := false;
    Close(workFile);
    exit;
  end;
  Close(workFile);
  {$I+}
  if LoadImage(font^.Data, filename, offset, header, error) then
    LoadFont := true
  else
    LoadFont := false;
  CalculateFontWidths(font);
end;

procedure CreateImgHeader(
  var header: TImgFileHeader;
  imgWidth, imgHeight: word;
  compressionType: TCompressionType;
  vgaPalette: TVgaPalette
);
begin
  FillChar(header, SizeOf(header), 0);
  with header do
  begin
    HeaderText := 'img';
    Version := ImgFileVersion;
    Width := imgWidth;
    Height := imgHeight;
    Compression := compressionType;
    Palette := vgaPalette;
  end;
end;

end.