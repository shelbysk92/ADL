unit Utils;

interface

uses
  Strings;

type
  TErrorSeverity =
  (
    esNone,
    esHint,
    esWarning,
    esError,
    esFatal
  );
  THexString = string[9];
  TErrorCode = word;
  TError = record
    ErrorCode: TErrorCode;
    Severity: TErrorSeverity;
    ErrorMessage: string;
  end;

const
  ecNone = 0;

  { IO Codes }
  ecFileNotFound = 101;
  ecFileCreateError = 102;
  ecFileOpenError = 103;
  ecFileReadError = 104;
  ecFileWriteError = 105;
  ecFileVersionError = 106;
  ecFileTypeError = 106;
  ecFileInvalid = 107;
  ecMouseError = 108;

  { Graphics errors }
  ecGraphicsNotSupported = 201;
  ecGraphicsDriverError = 202;
  ecGraphicsModeNotFound = 203;

  { Memory errors }
  ecMemoryReferenceNotFound = 301;
  ecInvalidMemoryReference = 302;
  ecNotEnoughMemory = 303;
  ecInvalidAllocSize = 304;
  ecXmsNotInitialized = 305;
  ecXmsNotSupported = 306;
  ecXmsError = 307;

  { Stream errors }
  ecSeekPastStreamEnd = 400;
  ecWritePastStreamEnd = 401;
  ecReadPastStreamEnd = 402;
  ecStreamSeekNotSupported = 403;
  ecStreamWriteNotSupported = 404;
  ecStreamReadNotSupported = 405;
  ecStreamNotOpen = 406;

  HexDigits: String[16] = '0123456789ABCDEF';

function IntToStr(num: longint): string;
function IntToHex(num: longint): THexString;
function MaxW(word1, word2: word): word;
function MinW(word1, word2: word): word;
function MaxL(long1, long2: longint): longint;
function MinL(long1, long2: longint): longint;
function FileExists(const name: string): boolean;
function GetExtension(const name: string): string;
function UpperCase(const name: string): string;
function NoError(var error: TError): boolean;
function ExtractFilePath(filename: string): string;
function Equal(var var1, var2; size: word): boolean;
procedure CreateError(var error: TError; errorCode: TErrorCode; severity: TErrorSeverity);
procedure ClearError(var error: TError);
procedure SwapL(var long1: longint; var long2: longint);
procedure SwapW(var word1: word; var word2: word);
procedure ClearVar(var variable);

implementation

uses
  Objects;

procedure ClearVar(var variable);
begin
  FillChar(variable, SizeOf(variable), 0);
end;

function NoError(var error: TError): boolean;
begin
  NoError := error.ErrorCode = ecNone;
end;

function Equal(var var1, var2; size: word): boolean;
var
  index: integer;
  byte1, byte2: PByte;
begin
  byte1 := @var1;
  byte2 := @var2;
  Equal := true;
  if (size <= 0) then exit;
  for index := 0 to size - 1 do
  begin
    if (byte1^ <> byte2^) then
    begin
      Equal := false;
      exit;
    end;
    Inc(byte1);
    Inc(byte2);
  end;
end;

procedure SwapL(var long1: longint; var long2: longint);
var
  temp: longint;
begin
  temp := long1;
  long1 := long2;
  long2 := temp;
end;

procedure SwapW(var word1: word; var word2: word);
var
  temp: word;
begin
  temp := word1;
  word1 := word2;
  word2 := temp;
end;

function ErrorMessage(errorCode: TErrorCode): string;
begin
  if (errorCode = ecFileNotFound) then
    ErrorMessage := 'File not found'
  else if (errorCode = ecFileCreateError) then
    ErrorMessage := 'File could not be created'
  else if (errorCode = ecFileOpenError) then
    ErrorMessage := 'File could not be opened'
  else if (errorCode = ecFileReadError) then
    ErrorMessage := 'Error writing file'
  else if (errorCode = ecFileWriteError) then
    ErrorMessage := 'Error writing file'
  else if (errorCode = ecFileVersionError) then
    ErrorMessage := 'File version mismatch'
  else if (errorCode = ecFileTypeError) then
    ErrorMessage := 'File type not supported'
  else if (errorCode = ecFileInvalid) then
    ErrorMessage := 'File is invalid'
  else if (errorCode = ecGraphicsNotSupported) then
    ErrorMessage := 'Graphics mode not supported'
  else if (errorCode = ecMemoryReferenceNotFound) then
    ErrorMessage := 'Memory reference not found'
  else if (errorCode = ecInvalidMemoryReference) then
    ErrorMessage := 'Invalid memory reference'
  else if (errorCode = ecNotEnoughMemory) then
    ErrorMessage := 'Not enough memory'
  else if (errorCode = ecInvalidAllocSize) then
    ErrorMessage := 'Invalid allocation size'
  else if (errorCode = ecGraphicsDriverError) then
    ErrorMessage := 'Graphics mode not supported'
  else if (errorCode = ecStreamSeekNotSupported) then
    ErrorMessage := 'Stream does not support seeking'
  else if (errorCode = ecStreamWriteNotSupported) then
    ErrorMessage := 'Stream does not support writing'
  else if (errorCode = ecStreamReadNotSupported) then
    ErrorMessage := 'Stream does not support reading'
  else if (errorCode = ecSeekPastStreamEnd) then
    ErrorMessage := 'Attempt to seek past end of stream'
  else if (errorCode = ecWritePastStreamEnd) then
    ErrorMessage := 'Attempt to write past end of stream'
  else if (errorCode = ecReadPastStreamEnd) then
    ErrorMessage := 'Attempt to read past end of stream'
  else if (errorCode = ecStreamNotOpen) then
    ErrorMessage := 'Stream is not open'
  else if (errorCode = ecXmsNotInitialized) then
    ErrorMessage := 'XMS memory could not be initialized'
  else if (errorCode = ecXmsNotSupported) then
    ErrorMessage := 'XMS memory is not supported'
  else if (errorCode = ecGraphicsModeNotFound) then
    ErrorMessage := 'Graphics mode not found'
  else
    ErrorMessage := 'Unknown error';
end;

function FileExists(const name: string): boolean;
var
  testFile: file;
begin
  {$I-}
  FileMode := 0;
  Assign(testFile, name);
  Reset(testFile);
  if (IOResult = 0) then
  begin
    FileExists := true;
    Close(testFile);
  end
  else
    FileExists := false;
  {$I+}
end;

procedure CreateError(var error: TError; errorCode: TErrorCode; severity: TErrorSeverity);
begin
  error.ErrorCode := errorCode;
  error.ErrorMessage := ErrorMessage(error.ErrorCode);
  error.Severity := severity;
end;

procedure ClearError(var error: TError);
begin
  FillChar(error, SizeOf(error), 0);
end;

function GetExtension(const name: string): string;
var
  dotPos: integer;
begin
  dotPos := Pos('.', name);
  if (dotPos < 0) then
    GetExtension := ''
  else
    GetExtension := Copy(name, dotPos, Length(name) - dotPos + 1);
end;

function UpperCase(const name: string): string;
var index: integer;
begin
  UpperCase := name;
  for index := 1 to Length(name) do
    UpperCase[index] := UpCase(name[index]);
end;

function MaxW(word1, word2: word): word;
begin
  MaxW := word1;
  if (word2 > word1) then MaxW := word2;
end;


function MinW(word1, word2: word): word;
begin
  MinW := word1;
  if (word2 < word1) then MinW := word2;
end;

function MaxL(long1, long2: longint): longint;
begin
  MaxL := long1;
  if (long2 > long1) then MaxL := long2;
end;


function MinL(long1, long2: longint): longint;
begin
  MinL := long1;
  if (long2 < long1) then MinL := long2;
end;

function IntToStr(num: longint): string;
var
  result: string;
begin
   Str(num, result);
   IntToStr := result;
end;


function IntToHex(num: longint): THexString;
var
  digit, numPos: byte;
  result: THexString;
  width: byte;
begin
  FillChar(result, SizeOf(result), ord('0'));
  result[1] := '$';
  if (num >= High(word)) then
    width := 8
  else if (num >= High(byte)) then
    width := 4
  else
    width := 2;

  result[0] := chr(width + 1);
  numPos := width + 1;
  while (num > 0) do
  begin
    result[numPos] := HexDigits[num mod 16 + 1];
    Dec(numPos);
    num := num div 16;
  end;
  IntToHex := result;
end;

function ExtractFilePath(filename: string): string;
var
  index: integer;
  result: string;
begin
  ExtractFilePath := '';
  if (Length(fileName) = 0) then exit;
  result := '';
  for index := Length(filename) downto 1 do
  begin
    if (filename[index] = '\') then
    begin
      result := Copy(filename, 1, index);
      break;
    end;
  end;
  ExtractFilePath := result;
end;

end.