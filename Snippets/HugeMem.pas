type
  voidp  = pointer;
  voidpf = voidp;
  HugePtr = voidpf;
  LH = record
    L, H : word;
  end;
  TMemRec = record
    orgvalue,
    value : pointer;
    size: longint;
  end;
  PFreeRec = ^TFreeRec;
  TFreeRec = record
    next: PFreeRec;
    size: Pointer;
  end;

const
  MaxAllocEntries = 50;
  allocatedCount : 0..MaxAllocEntries = 0;

var
  allocatedList : array[0..MaxAllocEntries-1] of TMemRec;

 function NewAllocation(ptr0, ptr : pointer; memsize : longint) : boolean;
 begin
   if (allocatedCount < MaxAllocEntries) and (ptr0 <> NIL) then
   begin
     with allocatedList[allocatedCount] do
     begin
       orgvalue := ptr0;
       value := ptr;
       size := memsize;
     end;
     Inc(allocatedCount);  { we don't check for duplicate }
     NewAllocation := TRUE;
   end
   else
     NewAllocation := FALSE;
 end;

function Normalized(p : pointer)  : pointer;
var
  count : word;
begin
  count := LH(p).L and $FFF0;
  Normalized := Ptr(LH(p).H + (count shr 4), LH(p).L and $F);
end;

procedure IncPtr(var p:pointer;count:word);
 { Increments pointer }
 begin
   inc(LH(p).L,count);
   if LH(p).L < count then
     inc(LH(p).H,SelectorInc);  { $1000 }
 end;

procedure FreeHuge(var p:HugePtr; size : longint);
const
  blocksize = $FFF0;
var
  block : word;
begin
  while size > 0 do
  begin
    { block := minimum(size, blocksize); }
    if size > blocksize then
      block := blocksize
    else
      block := size;

    dec(size,block);
    freemem(p,block);
    IncPtr(p,block);    { we may get ptr($xxxx, $fff8) and 31 bytes left }
    p := Normalized(p); { to free, so we must normalize }
  end;
end;

function FreeMemHuge(ptr : pointer) : boolean;
var
  i : integer; { -1..MaxAllocEntries }
begin
  FreeMemHuge := FALSE;
  i := allocatedCount - 1;
  while (i >= 0) do
  begin
    if (ptr = allocatedList[i].value) then
    begin
      with allocatedList[i] do
        FreeHuge(orgvalue, size);

      Move(allocatedList[i+1], allocatedList[i],
           SizeOf(TMemRec)*(allocatedCount - 1 - i));
      Dec(allocatedCount);
      FreeMemHuge := TRUE;
      break;
    end;
    Dec(i);
  end;
end;

procedure GetLargeMem(var memPtr: pointer; size: LongInt);
var
  block: word;
  prev, free: PFreeRec;
  temp, savedFreeList: pointer;
begin
  memPtr := nil;
  if (size > MaxAvail) then exit;
  if (size <= LargestVarSize) then begin
    GetMem(memPtr, size);
    exit;
  end;

  Inc(size, 15);
  prev := PFreeRec(@FreeList);
  free := prev^.Next;
  while (free <> HeapPtr) and (free^.size < size) do begin
    prev := free;
    free := prev^.next;
  end;
  if (next = HeapPtr) then exit;

  savedFreeList := FreeList;
  FreeList := free;

  while (size > 0) do begin
    block := MinW(size, LargestVarSize);
    Dec(size, block);
    GetMem(temp, block);
    if (temp = nil) then exit;
  end;

  memPtr := free;
  if (prev^.next <> FreeList) then begin
    prev^.next := FreeList;
    FreeList := savedFreeList;
  end;

  if (memPtr = nil) then exit;
  { return pointer with 0 offset }
  if (Ofs(memPtr^) <> 0) then memPtr := Ptr(Seg(memPtr^) + 1, 0);  { hack }
end;

procedure GetMemHuge(var p:HugePtr;memsize:Longint);
const
  blocksize = $FFF0;
var
  size : longint;
  prev,free : PFreeRec;
  save,temp : pointer;
  block : word;
begin
  p := NIL;
  { Handle the easy cases first }
  if memsize > maxavail then
    exit
  else
    if memsize <= blocksize then
    begin
      getmem(p, memsize);
      if not NewAllocation(p, p, memsize) then
      begin
        FreeMem(p, memsize);
        p := NIL;
      end;
    end
    else
    begin
      size := memsize + 15;

      { Find the block that has enough space }
      prev := PFreeRec(@freeList);
      free := prev^.next;
      while (free <> heapptr) and (ptr2int(free^.size) < size) do
      begin
        prev := free;
        free := prev^.next;
      end;

      { Now free points to a region with enough space; make it the first one and
        multiple allocations will be contiguous. }

      save := freelist;
      freelist := free;
      { In TP 6, this works; check against other heap managers }
      while size > 0 do
      begin
        { block := minimum(size, blocksize); }
        if size > blocksize then
          block := blocksize
        else
          block := size;
        dec(size,block);
        getmem(temp,block);
      end;

      { We've got what we want now; just sort things out and restore the
        free list to normal }

      p := free;
      if prev^.next <> freelist then
      begin
        prev^.next := freelist;
        freelist := save;
      end;

      if (p <> NIL) then
      begin
        { return pointer with 0 offset }
        temp := p;
        if Ofs(p^)<>0 Then
          p := Ptr(Seg(p^)+1,0);  { hack }
        if not NewAllocation(temp, p, memsize + 15) then
        begin
          FreeHuge(temp, size);
          p := NIL;
        end;
      end;
    end;
end;
