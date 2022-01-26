
run("Misc...", "divide=Infinity save");
testArg=0;

if(testArg!=0)
args = split(testArg,",");
else
args = split(getArgument(),",");

path = args[0];// full path
savedir = args[1];//save dir

open(path);

run("Split Channels");

imagesnum = nImages();
titlelist=getList("image.titles");

for(i=0; i<imagesnum; i++){
	selectWindow(titlelist[i]);
	run("Nrrd ... ", "nrrd="+savedir+"/C"+i+1+"-"+imagesnum+"ch.nrrd");
	close();
}

run("Quit");