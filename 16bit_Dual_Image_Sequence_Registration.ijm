//Dual Image Sequence Registration
//16bit output

Dialog.create("Register 16bit Image Sequences");
Dialog.addMessage("Register Source to Target");
Dialog.addMessage("Source will be conformed to the Target");
Dialog.addMessage("\n");
Dialog.addDirectory("Target Input Directory", "");
Dialog.addDirectory("Source Input Directory", "");
Dialog.addDirectory("Output Directory", "");
Dialog.addMessage("\n");
Dialog.addString("Prepend text to Target Image Sequence:", "Target-");
Dialog.addString("Prepend text to Source Image Sequence:", "Source1-");
Dialog.addMessage("\n");
Dialog.addNumber("Steps Per Scale Octave:",6);
Dialog.addMessage("Increases the number of correspondences. 10 or more can start to lose accuracy.");
Dialog.addMessage("\n");
Dialog.addNumber("Preserve frame numbers:",0);
Dialog.addMessage("Preserve the input frame numbers instead of starting from zero.\nEnter the first frame number of your image sequence.\nOtherwise, leave at 0 to output frames beginning from 0.");
Dialog.show();
targetpath=Dialog.getString();
source1path=Dialog.getString();
outputdir=Dialog.getString();
targetprefixtext=Dialog.getString();
source1prefixtext=Dialog.getString();
steps=toString(Dialog.getNumber());
preserveframes=Dialog.getNumber();
File.makeDirectory(outputdir + "Target");
File.makeDirectory(outputdir + "Source1");
outputtargetdir=outputdir + "Target/"
outputsourcedir=outputdir + "Source1/"

targetlist = getFileList(targetpath);
source1list = getFileList(source1path);


//Search for first frame that contains enough detail for masking.
setBatchMode(true);
print("Searching for frame with enough information for masking.");
var donem = false;//used to terminate loop
for (k=0; k<targetlist.length && !donem; k++) {
	targetnamem=targetprefixtext+pad(k+preserveframes);
	source1namem=source1prefixtext+pad(k+preserveframes);
	open(targetpath+targetlist[k]);
	convertto16bit();
   	rename(targetnamem);
	open(source1path+source1list[k]);
	convertto16bit();
    rename(source1namem);
	selectWindow(source1namem);
	getStatistics(area1m,mean1m);
	selectWindow(targetnamem);
	getStatistics(area3m,mean3m);
	selectWindow(source1namem);
	setLocation(0,0,960,960);
	if (mean1m > 8000) {
		setBatchMode("show");
		Dialog.create("Mask information");
		Dialog.addMessage("Does the frame have enough information for masking?");
		Dialog.addMessage("If so, check the checkbox and click OK.");
		Dialog.addMessage("If not, leave the checkbox alone and click OK to try again.");
		Dialog.addCheckbox("I'm ready to mask the frames.",false);
		Dialog.show();
		maskdetail=Dialog.getCheckbox();
		if (maskdetail == true) {
			run("Select None");
			setTool("rectangle");
			waitForUser("Source1 Mask","Draw a rectangle around the area that should not be feature matched.\nIf no mask is desired then press OK to continue to the Target image.");
			setBatchMode("hide");
			source1masktype=selectionType;
			if (source1masktype == 0 & maskdetail == true) {
				selectWindow(source1namem);
				if (source1masktype == 0) {
					getSelectionBounds(sm1x,sm1y,sm1w,sm1h);
					} else {
					print("No source mask defined. Moving on.");
					}
					selectWindow(targetnamem);
					run("Select None");
					setBatchMode("show");
					setTool("rectangle");
					waitForUser("Target Mask","Draw a rectangle around the area that should not be feature matched.\nIf no mask is desired then press OK to continue with registration.");
					setBatchMode("hide");
					targetmasktype=selectionType;
					if (targetmasktype == 0) {
					getSelectionBounds(tmx,tmy,tmw,tmh);
					} else {
					print("No target mask defined. Moving on.");
					}
					close(source1namem);
					close(targetnamem);
					donem=true;
			} 
		} 
	}
close(source1namem);
close(targetnamem);	
}
	

print("Searching for initial set of correspondences");
var donec = false; // used to terminate loop
for (j=0; j<targetlist.length && !donec; j++) {
	targetname=targetprefixtext+pad(j+preserveframes);
	source1name=source1prefixtext+pad(j+preserveframes);
	open(targetpath+targetlist[j]);
	convertto16bit();
   	rename(targetname);
	open(source1path+source1list[j]);
	convertto16bit();
    rename(source1name);
	selectWindow(source1name);
	getStatistics(area1,mean1);
	selectWindow(targetname);
	run("Enhance Local Contrast (CLAHE)", "blocksize=511 histogram=1024 maximum=5 mask=*None* fast_(less_accurate)");
	selectWindow(source1name);
	run("Enhance Local Contrast (CLAHE)", "blocksize=511 histogram=1024 maximum=5 mask=*None* fast_(less_accurate)");
	if (source1masktype == 0) {
		selectWindow(source1name);
		makeRectangle(sm1x,sm1y,sm1w,sm1h);
		setColor("black");
		fill();
		run("Select None");
	}
	if (targetmasktype == 0) {
		selectWindow(targetname);
		makeRectangle(tmx,tmy,tmw,tmh);
		setColor("black");
		fill();
		run("Select None");
	}
	selectWindow(targetname);
	twidth=1000 + getWidth();
	theight=1000 + getHeight();
	run("Canvas Size...", "width="+twidth+" height="+theight+" position=Center zero");
	
	SIFT(source1name,targetname,steps);
	selectWindow(source1name);
    s1type=selectionType();
	selectWindow(targetname);
	ttype1=selectionType();
	if (s1type & ttype1 == 10 && mean1 > 3072) {
		selectWindow(source1name);
		Roi.getCoordinates(s1x,s1y);
		selectWindow(targetname);
		Roi.getCoordinates(t1x,t1y);
	}
	if (s1type & ttype1 == 10 && mean1 > 3072 ) {
		print("Initial correspondences found");
		selectWindow(source1name);
		makeSelection("point hybrid yellow small",s1x,s1y);
		selectWindow(targetname);
		makeSelection("point hybrid yellow small",t1x,t1y);
		selectWindow(source1name);
		setSlice(1);
		selectWindow(targetname);
		setSlice(1);
		run("Landmark Correspondences", "source_image=["+source1name+"] template_image=["+targetname+"] transformation_method=[Least Squares] alpha=1 mesh_resolution=32 transformation_class=Affine interpolate");
		setLocation(320,480,320,240);
		rename("C1-"+source1name);
		selectWindow(source1name);
		setSlice(2);
		selectWindow(targetname);
		setSlice(2);
		run("Landmark Correspondences", "source_image=["+source1name+"] template_image=["+targetname+"] transformation_method=[Least Squares] alpha=1 mesh_resolution=32 transformation_class=Affine interpolate");
		setLocation(640,480,320,240);
		rename("C2-"+source1name);
		selectWindow(source1name);
		setSlice(3);
		selectWindow(targetname);
		setSlice(3);
		run("Landmark Correspondences", "source_image=["+source1name+"] template_image=["+targetname+"] transformation_method=[Least Squares] alpha=1 mesh_resolution=32 transformation_class=Affine interpolate");
		setLocation(960,480,320,240);
		rename("C3-"+source1name);
		
	while (isOpen("C1-" + source1name) != 1 && isOpen("C2-" + source1name) != 1 && isOpen("C3-" + source1name) != 1)
		{ 
			wait(100);
		}
	
		close(source1name);
		
		run("Concatenate...", "  title=[" + source1name + "] image1=[" + "C1-" + source1name + "] image2=[" + "C2-" + source1name + "] image3=[" + "C3-" + source1name + "]");
		setLocation(320,240,320,240);
		run("Make Composite", "display=Composite");
		setLocation(320,240,320,240);
		PREPLABELS();
		
		run("Concatenate...", "  title=[Common Cropping] image1=[" + targetname + "] image2=[" + source1name + "] image3=[-- None --]");
		run("Select None");
		setBatchMode("show");
		setLocation(0,0,960,960);
		setTool("rectangle");
		waitForUser("Common Cropping","Draw a rectangle around the area that should define the common active image area of all sources.\nUse the slider to check all 3 sources before continuing. \n Use Specify to fine tune the dimensions and location.");
		run("Specify...");
		setBatchMode("hide");
		getSelectionBounds(ccx,ccy,ccw,cch);
		close("Common Cropping");
		donec=true; //terminate the loop
    } else {
		close(source1name);
		close(targetname);
	}
}

//Start Registration from beginning of clip using initial transform found above as anchor if needed.
//Saves last known good set of correspondences and uses them on frames that have none.
print("Registration loop initialized.");
for (i=0; i<targetlist.length; i++) {
	showProgress(i+1, targetlist.length);
	targetname1=targetprefixtext+pad(i+preserveframes);
	sourcename1=source1prefixtext+pad(i+preserveframes);
	open(targetpath+targetlist[i]);
	setLocation(0,0,320,240);
	print("Import "+targetname1);
	convertto16bit();
	rename(targetname1);
	setLocation(0,0,320,240);
	rename(targetname1);
	open(source1path+source1list[i]);
	setLocation(0,240,320,240);
	print("Import "+sourcename1);
	convertto16bit();
    rename(sourcename1);
	
	print("Starting Elastic Registration");
	selectWindow(targetname1);
	run("Duplicate...", "title=T1-CLAHE");
	setLocation(320,0,320,240);
	run("Enhance Local Contrast (CLAHE)", "blocksize=511 histogram=1024 maximum=5 mask=*None* fast_(less_accurate)");
	selectWindow(sourcename1);
	run("Duplicate...", "title=S1T-CLAHE");
	setLocation(320,240,320,240);
	run("Enhance Local Contrast (CLAHE)", "blocksize=511 histogram=1024 maximum=5 mask=*None* fast_(less_accurate)");
		
	if (source1masktype == 0) {
		selectWindow("S1T-CLAHE");
		makeRectangle(sm1x,sm1y,sm1w,sm1h);
		setColor("black");
		fill();
		run("Select None");
	}
	if (targetmasktype == 0) {
		selectWindow("T1-CLAHE");
		makeRectangle(tmx,tmy,tmw,tmh);
		setColor("black");
		fill();
		run("Select None");
	}
	selectWindow("T1-CLAHE");
	twidth=1000 + getWidth();
	theight=1000 + getHeight();
	run("Canvas Size...", "width="+twidth+" height="+theight+" position=Center zero");
	selectWindow(targetname1);
	twidth=1000 + getWidth();
	theight=1000 + getHeight();
	run("Canvas Size...", "width="+twidth+" height="+theight+" position=Center zero");
	selectWindow("S1T-CLAHE");
	makeSelection("point hybrid yellow small",s1x,s1y);
	selectWindow("T1-CLAHE");
	makeSelection("point hybrid yellow small",t1x,t1y);
	run("Landmark Correspondences", "source_image=S1T-CLAHE template_image=T1-CLAHE transformation_method=[Least Squares] alpha=1 mesh_resolution=32 transformation_class=Affine interpolate");
	rename("S1-CLAHE");
	close("S1T-CLAHE");
	SIFT("S1-CLAHE","T1-CLAHE",steps);
	selectWindow("S1-CLAHE");
	s1typen=selectionType();
	if (s1typen == 10) {
	Roi.getCoordinates(ns1x,ns1y);
	}
	selectWindow("T1-CLAHE");
	t1typen=selectionType();
	if (t1typen == 10) {
	Roi.getCoordinates(nt1x,nt1y);
	}
	
	close("S1-CLAHE");
	selectWindow(sourcename1);
	setSlice(1);
	makeSelection("point hybrid yellow small",s1x,s1y);
	selectWindow(targetname1);
	setSlice(1);
	makeSelection("point hybrid yellow small",t1x,t1y);
	run("Landmark Correspondences", "source_image=["+sourcename1+"] template_image=["+targetname1+"] transformation_method=[Least Squares] alpha=1 mesh_resolution=32 transformation_class=Affine interpolate");
	rename("C1T");
	selectWindow("C1T");
	makeSelection("point hybrid yellow small",ns1x,ns1y);
	selectWindow(targetname1);
	makeSelection("point hybrid yellow small",nt1x,nt1y);
	run("Landmark Correspondences", "source_image=C1T template_image=["+targetname1+"] transformation_method=[Least Squares] alpha=1 mesh_resolution=32 transformation_class=Affine interpolate");
	setLocation(320,240,320,240);
	rename("C1-"+sourcename1);
	selectWindow(sourcename1);
	setSlice(2);
	makeSelection("point hybrid yellow small",s1x,s1y);
	selectWindow(targetname1);
	setSlice(2);
	makeSelection("point hybrid yellow small",t1x,t1y);
	run("Landmark Correspondences", "source_image=["+sourcename1+"] template_image=["+targetname1+"] transformation_method=[Least Squares] alpha=1 mesh_resolution=32 transformation_class=Affine interpolate");
	rename("C2T");
	selectWindow("C2T");
	makeSelection("point hybrid yellow small",ns1x,ns1y);
	selectWindow(targetname1);
	makeSelection("point hybrid yellow small",nt1x,nt1y);
	run("Landmark Correspondences", "source_image=C2T template_image=["+targetname1+"] transformation_method=[Least Squares] alpha=1 mesh_resolution=32 transformation_class=Affine interpolate");
	setLocation(320,240,320,240);
	rename("C2-"+sourcename1);
	selectWindow(sourcename1);
	setSlice(3);
	makeSelection("point hybrid yellow small",s1x,s1y);
	selectWindow(targetname1);
	setSlice(3);
	makeSelection("point hybrid yellow small",t1x,t1y);
	run("Landmark Correspondences", "source_image=["+sourcename1+"] template_image=["+targetname1+"] transformation_method=[Least Squares] alpha=1 mesh_resolution=32 transformation_class=Affine interpolate");
	rename("C3T");
	selectWindow("C3T");
	makeSelection("point hybrid yellow small",ns1x,ns1y);
	selectWindow(targetname1);
	makeSelection("point hybrid yellow small",nt1x,nt1y);
	run("Landmark Correspondences", "source_image=C3T template_image=["+targetname1+"] transformation_method=[Least Squares] alpha=1 mesh_resolution=32 transformation_class=Affine interpolate");
	setLocation(320,240,320,240);
	rename("C3-"+sourcename1);
		
	while (isOpen("C1-" + sourcename1) != 1 && isOpen("C2-" + sourcename1) != 1 && isOpen("C3-" + sourcename1) != 1)
		{ 
			wait(100);
		}
	
	close(sourcename1);
		
	selectWindow(targetname1);
	run("Select None");
	makeRectangle(ccx,ccy,ccw,cch);
	run("Crop");
	setLocation(0,0,320,240);
	PREPLABELS();
	saveAs("Tiff", outputtargetdir+targetname1+".tiff");
	wait(100);
	close(targetname1);
	close(targetname1+".tiff");
	
	run("Concatenate...", "  title=[" + sourcename1 + "] image1=[" + "C1-" + sourcename1 + "] image2=[" + "C2-" + sourcename1 + "] image3=[" + "C3-" + sourcename1 + "]");
	setLocation(320,240,320,240);
	run("Make Composite", "display=Composite");
	run("Select None");
	makeRectangle(ccx,ccy,ccw,cch);
	run("Crop");
	setLocation(320,240,320,240);
	PREPLABELS();
	saveAs("Tiff", outputsourcedir+sourcename1+".tiff");
	wait(100);
	close(sourcename1);
	close(sourcename1+".tiff");
	
	print("\\Clear");
	wait(100);
	while (nImages()>0) {
		selectImage(nImages());  
		wait(100);
		run("Close");
	}
}

	print("\\Clear");
	wait(500);
	while (nImages()>0) {
		selectImage(nImages());  
		wait(100);
		run("Close");
	}
//File.makeDirectory(outputsourcedir + "CM");
//wait(100);
cms1t = File.open(outputdir + "python-" + source1prefixtext + targetprefixtext + ".txt");
print(cms1t, "from color_matcher import ColorMatcher" + "\r"
+ "from color_matcher.io_handler import load_img_file, save_img_file, FILE_EXTS" + "\r"
+ "from color_matcher.normalizer import Normalizer" + "\r"
+ "import os" + "\r"
+ "\r"
+ "target_path = " + "r'" + outputtargetdir + "'" + "\r"
+ "source_path = " + "r'" + outputsourcedir + "'" + "\r"
+ "out_path = " + "r'" + outputsourcedir + "'" + "\r"
+ "target_filenames = os.listdir(target_path)" + "\r"
+ "source_filenames = os.listdir(source_path)" + "\r"
+ "\r"
+ "\r"
+ "cm = ColorMatcher()" + "\r"
+ "for i,j in zip(source_filenames,target_filenames):" + "\r"
+ "    img_source = load_img_file(source_path + str(i))" + "\r"
+ "    img_target = load_img_file(target_path + str(j))" + "\r"
+ "    img_res = cm.transfer(src=img_source, ref=img_target, method='hm-mvgd-hm')" + "\r"
+ "    img_res = Normalizer(img_res).uint16_norm()" + "\r"
+ "    save_img_file(img_res, os.path.join(out_path, str(i)))");
File.close(cms1t);

avs = File.open(outputdir + "avs-" + source1prefixtext + targetprefixtext + ".txt");
print(avs, "sfn="+ toString((0+preserveframes)) + "\r"
+ "efn=" + toString((targetlist.length+preserveframes-1)) + "\r"
+ "source1=imagesource(" + fromCharCode(34) + outputsourcedir + source1prefixtext  + "%06d.tiff" + fromCharCode(34) + ",start=sfn,end=efn,pixel_type=" + fromCharCode(34) + "RGB64" + fromCharCode(34) + ")" + "\r"
+ "target=imagesource(" + fromCharCode(34) + outputtargetdir + targetprefixtext +"%06d.tiff" + fromCharCode(34) + ",start=sfn,end=efn,pixel_type=" + fromCharCode(34) + "RGB64" + fromCharCode(34) + ")" + "\r"
+ "interleave(source1,target)" + "\r"
+ "return(last)");
File.close(avs);

wait(500);
exec("cmd", "/c", "rename " + outputdir + "python-" + source1prefixtext + targetprefixtext + ".txt " + source1prefixtext + targetprefixtext + ".py");
wait(500);
exec("cmd", "/c", "rename " + outputdir + "avs-" + source1prefixtext + targetprefixtext + ".txt " + source1prefixtext + targetprefixtext + ".avs");
wait(500);
exec("cmd", "/c", outputdir + source1prefixtext + targetprefixtext + ".py");
waitForUser("The registration macro is finished.");


function SIFT(sourcename,targetname,steps) {
run("Extract SIFT Correspondences", "source_image="+sourcename+" target_image="+targetname+" initial_gaussian_blur=1.60 steps_per_scale_octave="+steps+" minimum_image_size=64 maximum_image_size=1024 feature_descriptor_size=4 feature_descriptor_orientation_bins=8 closest/next_closest_ratio=0.92 filter maximal_alignment_error=25 minimal_inlier_ratio=0.05 minimal_number_of_inliers=20 expected_transformation=Affine");
}

function PREPLABELS() {
run("Remove Slice Labels");
setSlice(3);
run("Set Label...", "label=Blue");
setSlice(2);
run("Set Label...", "label=Green");
setSlice(1);
run("Set Label...", "label=Red");
}

function pad(n) {
     str = toString(n);
     while (lengthOf(str)<6)
     str = "0" + str;
     return str;
}

function convertto16bit() {
	if (bitDepth == 8){
		run("16-bit");
		run("Multiply...", "value=256.000");
		setMinAndMax(0, 65535);
		call("ij.ImagePlus.setDefault16bitRange", 16);
		setSlice(2);
		setMinAndMax(0,65535);
		call("ij.ImagePlus.setDefault16bitRange", 16);
		setSlice(3);
		setMinAndMax(0,65535);
		call("ij.ImagePlus.setDefault16bitRange", 16);
		} else if (bitDepth == 32){
		setMinAndMax(0, 65535);
		call("ij.ImagePlus.setDefault16bitRange", 16);
		run("16-bit");
		}	
	}
