//Dual Image Sequence Registration
//16bit output

Dialog.create("Register 16bit Image Sequences");
Dialog.addMessage("Register Source to Target")
Dialog.addString("Prefix text to Target Image Sequence:", "Target-");
Dialog.addString("Prefix text to Source Image Sequence:", "Source-");
Dialog.addMessage("\n");
Dialog.addNumber("Steps Per Scale Octave:",6);
Dialog.addMessage("Increases the number of correspondences. 10 or more can start to lose accuracy.");
Dialog.addMessage("\n");
Dialog.addNumber("Add Borders/Enlarge Canvas:",0);
Dialog.addCheckbox("Enhance Contrast (Slower, but Feature Extraction is better)",false);
Dialog.addCheckbox("Interactive Masking (Mask off areas that should not be Feature Matched)",false);
Dialog.addCheckbox("Enable Colormatching", false);
Dialog.addChoice("Colormatching Direction:", newArray("Source to Target", "Target to Source"), "Source to Target");
Dialog.addMessage("Note: Colormatching is not performed on frames without correspondence or missing frames.");
Dialog.addMessage("\n");
Dialog.addCheckbox("Attempt To Replace Missing Frames",false);
Dialog.addMessage("Missing frames must have a placeholder frame in place that is ENTIRELY black (RGB 0,0,0).\nIf Target AND Source are missing the same frame it will not be replaced.");
Dialog.addMessage("\n");
Dialog.addNumber("Preserve frame numbers:",0);
Dialog.addMessage("Preserve the input frame numbers instead of starting from zero.\nEnter the first frame number of your image sequence.\nOtherwise, leave at 0 to output frames beginning from 0.");
Dialog.show();
targetprefixtext=Dialog.getString();
sourceprefixtext=Dialog.getString();
steps=Dialog.getNumber();
steps=""+steps;
addborders=Dialog.getNumber();
CLAHE=Dialog.getCheckbox();
mask=Dialog.getCheckbox();
CM=Dialog.getCheckbox();
CMD=Dialog.getChoice();
RMF=Dialog.getCheckbox();
preserveframes=Dialog.getNumber();
if (CMD == "Source to Target") {
Direction = "2";
} else {
Direction = "1";
}
targetpath = getDirectory("Select Target Input Directory");
sourcepath = getDirectory("Select Source Input Directory (these files will be deformed to match the Target Files)");
if (addborders > 0) {
outputtargetdir=getDirectory("Select Target Output Directory for image sequence files:");
}
outputsourcedir = getDirectory("Select Source Output Directory for image sequence files:");
targetlist = getFileList(targetpath);
sourcelist = getFileList(sourcepath);

//Search for first frame that contains enough detail for a good transform.
setBatchMode(true);
print("Searching for initial set of correspondences");
var done = false; // used to terminate loop
for (j=0; j<targetlist.length && !done; j++) {
	targetname=targetprefixtext+pad(j+preserveframes);
	sourcename=sourceprefixtext+pad(j+preserveframes);
	run("Bio-Formats Importer", "open=["+targetpath+targetlist[j]+"] color_mode=Composite open_files rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
    convertto16bit();
	if (addborders > 0) {
	twidth=addborders + getWidth();
	theight=addborders + getHeight();
	run("Canvas Size...", "width="+twidth+" height="+theight+" position=Center zero");
	}
	rename(targetname);
	run("Duplicate...", "title=targetmask duplicate");
	run("Bio-Formats Importer", "open=["+sourcepath+sourcelist[j]+"] color_mode=Composite open_files rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
    convertto16bit();
	rename(sourcename);
	run("Duplicate...", "title=sourcemask duplicate");
	getStatistics(area,mean);
	SIFT(sourcename,targetname,steps);
    selectWindow(sourcename);
	stype0=selectionType();
	selectWindow(targetname);
	stype1=selectionType();
    if (stype0 & stype1 == 10 && mean > 3072) {
    	print("Correspondences Found.");
		selectWindow(sourcename);
		Roi.getCoordinates(sc1x,sc1y);
		Roi.getCoordinates(sc2x,sc2y);
		Roi.getCoordinates(sc3x,sc3y);
		selectWindow(targetname);
		Roi.getCoordinates(tc1x,tc1y);
		Roi.getCoordinates(tc2x,tc2y);
		Roi.getCoordinates(tc3x,tc3y);
		close(sourcename);
		close(targetname);
		print("Initial correspondences found");
		done=true; //terminate the loop
    } else {
		close(sourcename);
		close(targetname);
    }
}

//Interactive Masking
if (mask == true) {
selectWindow("sourcemask");
run("Select None");
setBatchMode("show");
setTool("rectangle");
waitForUser("Source Mask","Draw a rectangle around the area that should not be feature matched.\nIf no mask is desired then press OK to continue to the Target image.");
setBatchMode("hide");
sourcemasktype=selectionType;
if (sourcemasktype == 0) {
getSelectionBounds(smx,smy,smw,smh);
} else {
print("No source mask defined. Moving on.");
}
selectWindow("targetmask");
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
close("sourcemask");
close("targetmask");
}
//Start Registration from beginning of clip using initial transform found above as anchor if needed.
//Saves last known good set of correspondences and uses them on frames that have none.
print("Registration loop initialized");
for (i=0; i<targetlist.length; i++) {
	showProgress(i+1, targetlist.length);
	targetname1=targetprefixtext+pad(i+preserveframes);
	sourcename1=sourceprefixtext+pad(i+preserveframes);
	run("Bio-Formats Importer", "open=["+targetpath+targetlist[i]+"] color_mode=Composite open_files rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
	print("Import "+targetname1);
	convertto16bit();
	rename(targetname1);
	if (addborders > 0) {
	twidth=addborders + getWidth();
	theight=addborders + getHeight();
	run("Canvas Size...", "width="+twidth+" height="+theight+" position=Center zero");
	run("Duplicate...", "title=["+targetname1+"] duplicate");
	run("Split Channels");
	} else {
	run("Duplicate...", "title=["+targetname1+"] duplicate");
	run("Split Channels");
	}
	run("Bio-Formats Importer", "open=["+sourcepath+sourcelist[i]+"] color_mode=Composite open_files rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
	print("Import "+sourcename1);
    convertto16bit();
	rename(sourcename1);
	run("Duplicate...", "title=["+sourcename1+"] duplicate");
	run("Split Channels");
	if (CLAHE == true) {
	selectWindow("C1-"+targetname1);
	print("Enhance local contrast of "+targetname1+" Red channel");
	run("Enhance Local Contrast (CLAHE)", "blocksize=511 histogram=1024 maximum=5 mask=*None* fast_(less_accurate)");
	selectWindow("C2-"+targetname1);
	print("Enhance local contrast of "+targetname1+" Green channel");
	run("Enhance Local Contrast (CLAHE)", "blocksize=511 histogram=1024 maximum=5 mask=*None* fast_(less_accurate)");
	selectWindow("C3-"+targetname1);
	print("Enhance local contrast of "+targetname1+" Blue channel");
	run("Enhance Local Contrast (CLAHE)", "blocksize=511 histogram=1024 maximum=5 mask=*None* fast_(less_accurate)");
	selectWindow("C1-"+sourcename1);
	print("Enhance local contrast of "+sourcename1+" Red channel");
	run("Enhance Local Contrast (CLAHE)", "blocksize=511 histogram=1024 maximum=5 mask=*None* fast_(less_accurate)");
	selectWindow("C2-"+sourcename1);
	print("Enhance local contrast of "+sourcename1+" Green channel");
	run("Enhance Local Contrast (CLAHE)", "blocksize=511 histogram=1024 maximum=5 mask=*None* fast_(less_accurate)");
	selectWindow("C3-"+sourcename1);
	print("Enhance local contrast of "+sourcename1+" Blue channel");
	run("Enhance Local Contrast (CLAHE)", "blocksize=511 histogram=1024 maximum=5 mask=*None* fast_(less_accurate)");
	}
	if (mask == true) {
	 if (sourcemasktype == 0) {
	  selectWindow("C1-"+sourcename1);
	  makeRectangle(smx,smy,smw,smh);
	  setColor("black");
	  fill();
	  run("Select None");
	  selectWindow("C2-"+sourcename1);
	  makeRectangle(smx,smy,smw,smh);
	  setColor("black");
	  fill();
	  run("Select None");
	  selectWindow("C3-"+sourcename1);
	  makeRectangle(smx,smy,smw,smh);
	  setColor("black");
	  fill();
	  run("Select None");
	  }
	 if (targetmasktype == 0) {
	  selectWindow("C1-"+targetname1);
	  makeRectangle(tmx,tmy,tmw,tmh);
	  setColor("black");
	  fill();
	  run("Select None");
	  selectWindow("C2-"+targetname1);
	  makeRectangle(tmx,tmy,tmw,tmh);
	  setColor("black");
	  fill();
	  run("Select None");
	  selectWindow("C3-"+targetname1);
	  makeRectangle(tmx,tmy,tmw,tmh);
	  setColor("black");
	  fill();
	  run("Select None");
	  }
	 }
	print("Starting Feature Extraction and Matching");
	SIFT("C1-"+sourcename1,"C1-"+targetname1,steps);
	SIFT("C2-"+sourcename1,"C2-"+targetname1,steps);
	SIFT("C3-"+sourcename1,"C3-"+targetname1,steps);
	selectWindow("C1-"+sourcename1);
	stype2=selectionType();
	selectWindow("C1-"+targetname1);
	stype3=selectionType();
	selectWindow("C2-"+sourcename1);
	stype4=selectionType();
	selectWindow("C2-"+targetname1);
	stype5=selectionType();
	selectWindow("C3-"+sourcename1);
	stype6=selectionType();
	selectWindow("C3-"+targetname1);
	stype7=selectionType();
	if (stype2==10 && stype3==10 && stype4==10 && stype5==10 && stype6==10 && stype7==10) {
		selectWindow("C1-"+sourcename1);
		Roi.getCoordinates(sc1x,sc1y);
		selectWindow("C2-"+sourcename1);
		Roi.getCoordinates(sc2x,sc2y);
		selectWindow("C3-"+sourcename1);
		Roi.getCoordinates(sc3x,sc3y);
		selectWindow("C1-"+targetname1);
		Roi.getCoordinates(tc1x,tc1y);
		selectWindow("C2-"+targetname1);
		Roi.getCoordinates(tc2x,tc2y);
		selectWindow("C3-"+targetname1);
		Roi.getCoordinates(tc3x,tc3y);
		sx=Array.concat(sc1x,sc2x,sc3x);
		sy=Array.concat(sc1y,sc2y,sc3y);
		tx=Array.concat(tc1x,tc2x,tc3x);
		ty=Array.concat(tc1y,tc2y,tc3y);
		close("C1-"+sourcename1);
		close("C2-"+sourcename1);
		close("C3-"+sourcename1);
		close("C1-"+targetname1);
		close("C2-"+targetname1);
		close("C3-"+targetname1);
		selectWindow(sourcename1);
		run("Split Channels");
		selectWindow(targetname1);
		run("Split Channels");
		selectWindow("C1-"+sourcename1);
		makeSelection("point hybrid yellow small",sx,sy);
		selectWindow("C2-"+sourcename1);
		makeSelection("point hybrid yellow small",sx,sy);
		selectWindow("C3-"+sourcename1);
		makeSelection("point hybrid yellow small",sx,sy);
		selectWindow("C1-"+targetname1);
		makeSelection("point hybrid yellow small",tx,ty);
		selectWindow("C2-"+targetname1);
		makeSelection("point hybrid yellow small",tx,ty);
		selectWindow("C3-"+targetname1);
		makeSelection("point hybrid yellow small",tx,ty);
		print("Starting Elastic Registration");
		run("bUnwarpJ", "source_image=["+"C1-"+sourcename1+"] target_image=["+"C1-"+targetname1+"] registration=Mono image_subsample_factor=0 initial_deformation=[Very Coarse] final_deformation=Fine divergence_weight=0 curl_weight=0 landmark_weight=1 image_weight=0 consistency_weight=0 stop_threshold=0.01");
		close("C1-"+sourcename1);
		selectWindow("Registered Source Image");
		run("Slice Remover", "first=2 last=3 increment=1");
		rename("C1-"+sourcename1);
		convertto16bit();
		run("bUnwarpJ", "source_image=["+"C2-"+sourcename1+"] target_image=["+"C2-"+targetname1+"] registration=Mono image_subsample_factor=0 initial_deformation=[Very Coarse] final_deformation=Fine divergence_weight=0 curl_weight=0 landmark_weight=1 image_weight=0 consistency_weight=0 stop_threshold=0.01");
		close("C2-"+sourcename1);
		selectWindow("Registered Source Image");
		run("Slice Remover", "first=2 last=3 increment=1");
		rename("C2-"+sourcename1);
		convertto16bit();
		run("bUnwarpJ", "source_image=["+"C3-"+sourcename1+"] target_image=["+"C3-"+targetname1+"] registration=Mono image_subsample_factor=0 initial_deformation=[Very Coarse] final_deformation=Fine divergence_weight=0 curl_weight=0 landmark_weight=1 image_weight=0 consistency_weight=0 stop_threshold=0.01");
		close("C3-"+sourcename1);
		selectWindow("Registered Source Image");
		run("Slice Remover", "first=2 last=3 increment=1");
		rename("C3-"+sourcename1);
		convertto16bit();
		if (CM == true) {
		run("Concatenate...", "title=C1 open image1=["+"C1-"+sourcename1+"] image2=["+"C1-"+targetname1+"]");
		run("Stack Histogram Match", "referenceslice=["+Direction+"]");
		run("Remove Slice Labels");
		run("Stack to Images");
		selectWindow("C1-0001");
		rename("C1-"+sourcename1);
		selectWindow("C1-0002");
		rename("C1-"+targetname1);
		close("C1");
		close("Histogram-matched-C1");
		run("Concatenate...", "title=C2 open image1=["+"C2-"+sourcename1+"] image2=["+"C2-"+targetname1+"]");
		run("Stack Histogram Match", "referenceslice=["+Direction+"]");
		run("Remove Slice Labels");
		run("Stack to Images");
		selectWindow("C2-0001");
		rename("C2-"+sourcename1);
		selectWindow("C2-0002");
		rename("C2-"+targetname1);
		close("C2");
		close("Histogram-matched-C2");
		run("Concatenate...", "title=C3 open image1=["+"C3-"+sourcename1+"] image2=["+"C3-"+targetname1+"]");
		run("Stack Histogram Match", "referenceslice=["+Direction+"]");
		run("Remove Slice Labels");
		run("Stack to Images");
		selectWindow("C3-0001");
		rename("C3-"+sourcename1);
		selectWindow("C3-0002");
		rename("C3-"+targetname1);
		close("C3");
		close("Histogram-matched-C3");
		}
		run("Concatenate...", "open image1=["+"C1-"+sourcename1+"] image2=["+"C2-"+sourcename1+"] image3=["+"C3-"+sourcename1+"]");
		run("Make Composite", "display=Composite");
		convertto16bit();
		PREPLABELS();
		saveAs("Tiff", outputsourcedir+sourcename1+".tif");
		close(sourcename1+".tif");
		if (addborders > 0) {
		run("Concatenate...", "open image1=["+"C1-"+targetname1+"] image2=["+"C2-"+targetname1+"] image3=["+"C3-"+targetname1+"]");
		run("Make Composite", "display=Composite");
		convertto16bit();
		PREPLABELS();
		saveAs("Tiff", outputtargetdir+targetname1+".tif");
		close(targetname1+".tif");
		} else {
		close("C1-"+targetname1);
		close("C2-"+targetname1);
		close("C3-"+targetname1);
		}
		} else {
		close("C1-"+sourcename1);
		close("C2-"+sourcename1);
		close("C3-"+sourcename1);
		close("C1-"+targetname1);
		close("C2-"+targetname1);
		close("C3-"+targetname1);
		selectWindow(sourcename1);
		smean=getValue("Mean");
		run("Split Channels");
		selectWindow(targetname1);
		tmean=getValue("Mean");
		run("Split Channels");
		selectWindow("C1-"+sourcename1);
		makeSelection("point hybrid yellow small",sx,sy);
		selectWindow("C2-"+sourcename1);
		makeSelection("point hybrid yellow small",sx,sy);
		selectWindow("C3-"+sourcename1);
		makeSelection("point hybrid yellow small",sx,sy);
		selectWindow("C1-"+targetname1);
		makeSelection("point hybrid yellow small",tx,ty);
		selectWindow("C2-"+targetname1);
		makeSelection("point hybrid yellow small",tx,ty);
		selectWindow("C3-"+targetname1);
		makeSelection("point hybrid yellow small",tx,ty);
		print("Starting Elastic Registration");
		run("bUnwarpJ", "source_image=["+"C1-"+sourcename1+"] target_image=["+"C1-"+targetname1+"] registration=Mono image_subsample_factor=0 initial_deformation=[Very Coarse] final_deformation=Fine divergence_weight=0 curl_weight=0 landmark_weight=1 image_weight=0 consistency_weight=0 stop_threshold=0.01");
		close("C1-"+sourcename1);
		selectWindow("Registered Source Image");
		run("Slice Remover", "first=2 last=3 increment=1");
		rename("C1-"+sourcename1);
		convertto16bit();
		run("bUnwarpJ", "source_image=["+"C2-"+sourcename1+"] target_image=["+"C2-"+targetname1+"] registration=Mono image_subsample_factor=0 initial_deformation=[Very Coarse] final_deformation=Fine divergence_weight=0 curl_weight=0 landmark_weight=1 image_weight=0 consistency_weight=0 stop_threshold=0.01");
		close("C2-"+sourcename1);
		selectWindow("Registered Source Image");
		run("Slice Remover", "first=2 last=3 increment=1");
		rename("C2-"+sourcename1);
		convertto16bit();
		run("bUnwarpJ", "source_image=["+"C3-"+sourcename1+"] target_image=["+"C3-"+targetname1+"] registration=Mono image_subsample_factor=0 initial_deformation=[Very Coarse] final_deformation=Fine divergence_weight=0 curl_weight=0 landmark_weight=1 image_weight=0 consistency_weight=0 stop_threshold=0.01");
		close("C3-"+sourcename1);
		selectWindow("Registered Source Image");
		run("Slice Remover", "first=2 last=3 increment=1");
		rename("C3-"+sourcename1);
		convertto16bit();
		if (RMF == true && (tmean > 0 && smean == 0)) {
		close("C1-"+sourcename1);
		close("C2-"+sourcename1);
		close("C3-"+sourcename1);
		run("Concatenate...", "open image1=["+"C1-"+targetname1+"] image2=["+"C2-"+targetname1+"] image3=["+"C3-"+targetname1+"]");
		run("Make Composite", "display=Composite");
		PREPLABELS();
		if (addborders > 0) {
		saveAs("Tiff", outputtargetdir+targetname1+".tif");
		}
		saveAs("Tiff", outputsourcedir+sourcename1+".tif");
		close(sourcename1+".tif");
		} else if ( RMF == true && (tmean == 0 && smean > 0)) {
		run("Concatenate...", "open image1=["+"C1-"+sourcename1+"] image2=["+"C2-"+sourcename1+"] image3=["+"C3-"+sourcename1+"]");
		run("Make Composite", "display=Composite");
		PREPLABELS();
		if (addborders > 0) {
		saveAs("Tiff", outputtargetdir+targetname1+".tif");
		}
		saveAs("Tiff", outputsourcedir+sourcename1+".tif");
		close(sourcename1+".tif");
		close("C1-"+targetname1);
		close("C2-"+targetname1);
		close("C3-"+targetname1);
		} else {
		run("Concatenate...", "open image1=["+"C1-"+sourcename1+"] image2=["+"C2-"+sourcename1+"] image3=["+"C3-"+sourcename1+"]");
		run("Make Composite", "display=Composite");
		PREPLABELS();
		saveAs("Tiff", outputsourcedir+sourcename1+".tif");
		close(sourcename1+".tif");
		if (addborders > 0) {
		run("Concatenate...", "open image1=["+"C1-"+targetname1+"] image2=["+"C2-"+targetname1+"] image3=["+"C3-"+targetname1+"]");
		run("Make Composite", "display=Composite");
		PREPLABELS();
		saveAs("Tiff", outputtargetdir+targetname1+".tif");
		close(targetname1+".tif");
		} else {
		close("C1-"+targetname1);
		close("C2-"+targetname1);
		close("C3-"+targetname1);
		}
		}
}
	print("\\Clear");
	call("java.lang.System.gc");
}

setBatchMode("exit and display");
call("java.lang.System.gc");
beep();
waitForUser("The registration macro is finished.");

//function IMPORT() {
//
//}

function SIFT(sourcename,targetname,steps) {
run("Extract SIFT Correspondences", "source_image="+sourcename+" target_image="+targetname+" initial_gaussian_blur=1.60 steps_per_scale_octave="+steps+" minimum_image_size=64 maximum_image_size=1024 feature_descriptor_size=4 feature_descriptor_orientation_bins=8 closest/next_closest_ratio=0.92 filter maximal_alignment_error=25 minimal_inlier_ratio=0.05 minimal_number_of_inliers=20 expected_transformation=Affine");
}

function PREPLABELS() {
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
		run("Remove Slice Labels");		
}
