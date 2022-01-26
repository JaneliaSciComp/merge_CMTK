
run("Misc...", "divide=Infinity save");
testArg=0;

if(testArg!=0)
args = split(testArg,",");
else
args = split(getArgument(),",");

dir = args[0];// dir for 
savepath = args[1];//save path for merged file .v3draw

print("dir macro; "+dir);
print("savepath; "+savepath);

//list=getFileList(dir);

if(File.exists(dir+"C2-2ch_transformed.nrrd"))
open(dir+"C2-2ch_transformed.nrrd");// check if same z num

if(File.exists(dir+"C3-3ch.nrrd"))
open(dir+"C3-3ch.nrrd");

if(File.exists(dir+"C2-3ch.nrrd"))
open(dir+"C2-3ch.nrrd");

if(File.exists(dir+"C1-3ch.nrrd"))
open(dir+"C1-3ch.nrrd");

numimage=nImages();

if(numimage==4)
run("Merge Channels...", "c1=C2-2ch_transformed.nrrd c2=C3-3ch.nrrd c3=C2-3ch.nrrd c4=C1-3ch.nrrd create");
else
exit("there is no 4ch before merging");


run("V3Draw...", "save="+savepath+"");
close();


run("Quit");