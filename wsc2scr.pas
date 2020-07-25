program wsc2scr;

var
	buffer	:	array of byte;
	fin	:	file of byte;
	fout	:	file of byte;
	fsize	:	int64;
	i	:	longint;
begin
//{$I}
	if argc<3 then 
		begin
			writeln('Usage: wsc2scr <Input File> <Output File>');
			halt;
		end;
	writeln('Assign input file...');
	assign(fin,argv[1]);
	reset(fin,1);
	seek(fin,0);
	fsize:=filesize(fin);
	setlength(buffer,fsize);
	writeln('Reading file...');
//	BlockRead(fin,buffer,fsize);//Segmentation fault
	for i:=0 to fsize-1 do
		read(fin,buffer[i]);
	close(fin);
	writeln('Perform decryption...');
	for i:=0 to fsize-1 do
		buffer[i]:=(buffer[i] shr 2) or (buffer[i] shl 6);
	writeln('Writing...');
	assign(fout,argv[2]);
	rewrite(fout,1);
	for i:=0 to fsize-1 do
		write(fout,buffer[i]);
//	blockwrite(fout,buffer,fsize);
	close(fout);
	writeln('Done');
end.
