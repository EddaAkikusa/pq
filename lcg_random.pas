unit lcg_random;
// Delphi compatible LCG random number generator routines for Freepascal.
// (c)2017, Thaddy de Koning. Use as you like
// Algorithm, Delphi multiplier and increment taken from:
// https://en.wikipedia.org/wiki/Linear_congruential_generator
// The default Delphi RandomSeed is determined as zero.
{$ifdef fpc}{$mode objfpc}{$endif}

interface

function LCGRandom: extended; overload;inline;
function LCGRandom(const range:longint):longint;overload;inline;

implementation

function IM:cardinal;inline;
begin
  RandSeed := RandSeed * 134775813  + 1;
  Result := RandSeed;
end;

function LCGRandom: extended; overload;inline;
begin
  Result := IM * 2.32830643653870e-10;
end;

function LCGRandom(const range:longint):longint;overload;inline;
begin
  Result := IM * range shr 32;
end;

end.