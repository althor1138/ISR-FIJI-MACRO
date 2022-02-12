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
Dialog.addNumber("Wait time between commands:",100);
Dialog.addMessage("Add time in milliseconds between commands to allow the macro to execute properly."
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
waittime=Dialog.getNumber();
if (CMD == "Source to Target") {
Direction = "2";
} else {
Direction = "1";
}
targetpath = getDirectory("Select Target Input Directory");
wait(waittime);
sourcepath = getDirectory("Select Source Input Directory (these files will be deformed to match the Target Files)");
wait(waittime);
if (addborders > 0) {
outputtargetdir=getDirectory("Select Target Output Directory for image sequence files:");
wait(waittime);
}
outputsourcedir = getDirectory("Select Source Output Directory for image sequence files:");
wait(waittime);
targetlist = getFileList(targetpath);
wait(waittime);
sourcelist = getFileList(sourcepath);
wait(waittime);

//Search for first frame that contains enough detail for a good transform.
setBatchMode(true);
wait(waittime);
print("Searching for initial set of correspondences");
wait(waittime);
var done = false; // used to terminate loop
for (j=0; j<targetlist.length && !done; j++) {
	wait(waittime);
	targetname=targetprefixtext+pad(j+preserveframes);
	wait(waittime);
	sourcename=sourceprefixtext+pad(j+preserveframes);
	wait(waittime);
	run("Bio-Formats Importer", "open=["+targetpath+targetlist[j]+"] color_mode=Composite open_files rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
	wait(waittime);
     	convertto16bit();
     	wait(waittime);
	if (addborders > 0) {
	twidth=addborders + getWidth();
	wait(waittime);
	theight=addborders + getHeight();
	wait(waittime);
	run("Canvas Size...", "width="+twidth+" height="+theight+" position=Center zero");
	wait(waittime);
	}
	rename(targetname);
	setLocation(0,0,320,240);
	if (mask == true) {
	wait(waittime);
	run("Duplicate...", "title=targetmask");
	setSlice(1);
	setLocation(320,0,320,240);
	}
	wait(waittime);
	run("Bio-Formats Importer", "open=["+sourcepath+sourcelist[j]+"] color_mode=Composite open_files rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
	wait(waittime);
    	convertto16bit();
    	wait(waittime);
	rename(sourcename);
	setLocation(0,240,320,240);
	if (mask == true) {
	wait(waittime);
	run("Duplicate...", "title=sourcemask");
	setSlice(1);
	setLocation(320,240,320,240);
	wait(waittime);
	}
	selectWindow(sourcename);
	getStatistics(area,mean);
	wait(waittime);
	SIFT(sourcename,targetname,steps);
	wait(waittime);
    	selectWindow(sourcename);
    	wait(waittime);
	stype0=selectionType();
	wait(waittime);
	selectWindow(targetname);
	wait(waittime);
	stype1=selectionType();
	wait(waittime);
    if (stype0 & stype1 == 10 && mean > 3072) {
    	wait(waittime);
    	print("Correspondences Found.");
    	wait(waittime);
		selectWindow(sourcename);
		wait(waittime);
		Roi.getCoordinates(sc01x,sc01y);
		wait(waittime);
		selectWindow(targetname);
		wait(waittime);
		Roi.getCoordinates(tc01x,tc01y);
		wait(waittime);
		close(sourcename);
		wait(waittime);
		close(targetname);
		wait(waittime);
		print("Initial correspondences found");
		wait(waittime);
		done=true; //terminate the loop
    } else {
		wait(waittime);
		close(sourcename);
		wait(waittime);
		close(targetname);
		wait(waittime);
    }
}

//Interactive Masking
if (mask == true) {
wait(waittime);
selectWindow("sourcemask");
wait(waittime);
run("Select None");
wait(waittime);
setBatchMode("show");
wait(waittime);
setTool("rectangle");
wait(waittime);
waitForUser("Source Mask","Draw a rectangle around the area that should not be feature matched.\nIf no mask is desired then press OK to continue to the Target image.");
wait(waittime);
setBatchMode("hide");
wait(waittime);
sourcemasktype=selectionType;
wait(waittime);
if (sourcemasktype == 0) {
wait(waittime);
getSelectionBounds(smx,smy,smw,smh);
wait(waittime);
} else {
wait(waittime);
print("No source mask defined. Moving on.");
wait(waittime);
}
wait(waittime);
selectWindow("targetmask");
wait(waittime);
run("Select None");
wait(waittime);
setBatchMode("show");
wait(waittime);
setTool("rectangle");
wait(waittime);
waitForUser("Target Mask","Draw a rectangle around the area that should not be feature matched.\nIf no mask is desired then press OK to continue with registration.");
wait(waittime);
setBatchMode("hide");
wait(waittime);
targetmasktype=selectionType;
wait(waittime);
if (targetmasktype == 0) {
wait(waittime);
getSelectionBounds(tmx,tmy,tmw,tmh);
wait(waittime);
} else {
wait(waittime);
print("No target mask defined. Moving on.");
wait(waittime);
}
wait(waittime);
close("sourcemask");
wait(waittime);
close("targetmask");
wait(waittime);
}
wait(waittime);
setBatchMode(false);
wait(waittime);
//Start Registration from beginning of clip using initial transform found above as anchor if needed.
//Saves last known good set of correspondences and uses them on frames that have none.
print("Registration loop initialized");
for (i=0; i<targetlist.length; i++) {
	showProgress(i+1, targetlist.length);
	wait(waittime);
	targetname1=targetprefixtext+pad(i+preserveframes);
	wait(waittime);
	sourcename1=sourceprefixtext+pad(i+preserveframes);
	wait(waittime);
	run("Bio-Formats Importer", "open=["+targetpath+targetlist[i]+"] color_mode=Composite open_files rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
	setLocation(0,0,320,240);
	wait(waittime);
	print("Import "+targetname1);
	wait(waittime);
	convertto16bit();
	wait(waittime);
	rename(targetname1);
	wait(waittime);
	if (addborders > 0) {
	wait(waittime);
	twidth=addborders + getWidth();
	wait(waittime);
	theight=addborders + getHeight();
	wait(waittime);
	run("Canvas Size...", "width="+twidth+" height="+theight+" position=Center zero");
	setLocation(0,0,320,240);
	wait(waittime);
	run("Duplicate...", "title=["+targetname1+"] duplicate");
	wait(waittime);
	run("Split Channels");
	wait(waittime);
	selectWindow("C1-"+targetname1);
	setLocation(320,0,320,240);
	wait(waittime);
	selectWindow("C2-"+targetname1);
	setLocation(640,0,320,240);
	wait(waittime);
	selectWindow("C3-"+targetname1);
	setLocation(960,0,320,240);
	wait(waittime);
	} else {
	wait(waittime);
	run("Duplicate...", "title=["+targetname1+"] duplicate");
	wait(waittime);
	run("Split Channels");
	wait(waittime);
	selectWindow("C1-"+targetname1);
	setLocation(320,0,320,240);
	wait(waittime);
	selectWindow("C2-"+targetname1);
	setLocation(640,0,320,240);
	wait(waittime);
	selectWindow("C3-"+targetname1);
	setLocation(960,0,320,240);
	wait(waittime);
	}
	wait(waittime);
	run("Bio-Formats Importer", "open=["+sourcepath+sourcelist[i]+"] color_mode=Composite open_files rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
	setLocation(0,240,320,240);
	wait(waittime);
	print("Import "+sourcename1);
	wait(waittime);
    	convertto16bit();
    	wait(waittime);
	rename(sourcename1);
	wait(waittime);
	run("Duplicate...", "title=["+sourcename1+"] duplicate");
	wait(waittime);
	run("Split Channels");
	wait(waittime);
	selectWindow("C1-"+sourcename1);
	setLocation(320,240,320,240);
	wait(waittime);
	selectWindow("C2-"+sourcename1);
	setLocation(640,240,320,240);
	wait(waittime);
	selectWindow("C3-"+sourcename1);
	setLocation(960,240,320,240);
	wait(waittime);
	if (CLAHE == true) {
	wait(waittime);
	selectWindow("C1-"+targetname1);
	wait(waittime);
	print("Enhance local contrast of "+targetname1+" Red channel");
	wait(waittime);
	run("Enhance Local Contrast (CLAHE)", "blocksize=511 histogram=1024 maximum=5 mask=*None* fast_(less_accurate)");
	wait(waittime);
	selectWindow("C2-"+targetname1);
	wait(waittime);
	print("Enhance local contrast of "+targetname1+" Green channel");
	wait(waittime);
	run("Enhance Local Contrast (CLAHE)", "blocksize=511 histogram=1024 maximum=5 mask=*None* fast_(less_accurate)");
	wait(waittime);
	selectWindow("C3-"+targetname1);
	wait(waittime);
	print("Enhance local contrast of "+targetname1+" Blue channel");
	wait(waittime);
	run("Enhance Local Contrast (CLAHE)", "blocksize=511 histogram=1024 maximum=5 mask=*None* fast_(less_accurate)");
	wait(waittime);
	selectWindow("C1-"+sourcename1);
	wait(waittime);
	print("Enhance local contrast of "+sourcename1+" Red channel");
	wait(waittime);
	run("Enhance Local Contrast (CLAHE)", "blocksize=511 histogram=1024 maximum=5 mask=*None* fast_(less_accurate)");
	wait(waittime);
	selectWindow("C2-"+sourcename1);
	wait(waittime);
	print("Enhance local contrast of "+sourcename1+" Green channel");
	wait(waittime);
	run("Enhance Local Contrast (CLAHE)", "blocksize=511 histogram=1024 maximum=5 mask=*None* fast_(less_accurate)");
	wait(waittime);
	selectWindow("C3-"+sourcename1);
	wait(waittime);
	print("Enhance local contrast of "+sourcename1+" Blue channel");
	wait(waittime);
	run("Enhance Local Contrast (CLAHE)", "blocksize=511 histogram=1024 maximum=5 mask=*None* fast_(less_accurate)");
	wait(waittime);
	}
	if (mask == true) {
	 if (sourcemasktype == 0) {
	  wait(waittime);
	  selectWindow("C1-"+sourcename1);
	  wait(waittime);
	  makeRectangle(smx,smy,smw,smh);
	  wait(waittime);
	  setColor("black");
	  wait(waittime);
	  fill();
	  wait(waittime);
	  run("Select None");
	  wait(waittime);
	  selectWindow("C2-"+sourcename1);
	  wait(waittime);
	  makeRectangle(smx,smy,smw,smh);
	  wait(waittime);
	  setColor("black");
	  wait(waittime);
	  fill();
	  wait(waittime);
	  run("Select None");
	  wait(waittime);
	  selectWindow("C3-"+sourcename1);
	  wait(waittime);
	  makeRectangle(smx,smy,smw,smh);
	  wait(waittime);
	  setColor("black");
	  wait(waittime);
	  fill();
	  wait(waittime);
	  run("Select None");
	  wait(waittime);
	  }
	 if (targetmasktype == 0) {
	  wait(waittime);
	  selectWindow("C1-"+targetname1);
	  wait(waittime);
	  makeRectangle(tmx,tmy,tmw,tmh);
	  wait(waittime);
	  setColor("black");
	  wait(waittime);
	  fill();
	  wait(waittime);
	  run("Select None");
	  wait(waittime);
	  selectWindow("C2-"+targetname1);
	  wait(waittime);
	  makeRectangle(tmx,tmy,tmw,tmh);
	  wait(waittime);
	  setColor("black");
	  wait(waittime);
	  fill();
	  wait(waittime);
	  run("Select None");
	  wait(waittime);
	  selectWindow("C3-"+targetname1);
	  wait(waittime);
	  makeRectangle(tmx,tmy,tmw,tmh);
	  wait(waittime);
	  setColor("black");
	  wait(waittime);
	  fill();
	  wait(waittime);
	  run("Select None");
	  wait(waittime);
	  }
	 }
	wait(waittime);
	print("Starting Feature Extraction and Matching");
	wait(waittime);
	SIFT("C1-"+sourcename1,"C1-"+targetname1,steps);
	wait(waittime);
	SIFT("C2-"+sourcename1,"C2-"+targetname1,steps);
	wait(waittime);
	SIFT("C3-"+sourcename1,"C3-"+targetname1,steps);
	wait(waittime);
	selectWindow("C1-"+sourcename1);
	wait(waittime);
	stype2=selectionType();
	wait(waittime);
	selectWindow("C1-"+targetname1);
	wait(waittime);
	stype3=selectionType();
	wait(waittime);
	selectWindow("C2-"+sourcename1);
	wait(waittime);
	stype4=selectionType();
	wait(waittime);
	selectWindow("C2-"+targetname1);
	wait(waittime);
	stype5=selectionType();
	wait(waittime);
	selectWindow("C3-"+sourcename1);
	wait(waittime);
	stype6=selectionType();
	wait(waittime);
	selectWindow("C3-"+targetname1);
	wait(waittime);
	stype7=selectionType();
	wait(waittime);
	if (stype2==10 && stype3==10 && stype4==10 && stype5==10 && stype6==10 && stype7==10) {
		wait(waittime);
		selectWindow("C1-"+sourcename1);
		wait(waittime);
		Roi.getCoordinates(sc1x,sc1y);
		wait(waittime);
		selectWindow("C2-"+sourcename1);
		wait(waittime);
		Roi.getCoordinates(sc2x,sc2y);
		wait(waittime);
		selectWindow("C3-"+sourcename1);
		wait(waittime);
		Roi.getCoordinates(sc3x,sc3y);
		wait(waittime);
		selectWindow("C1-"+targetname1);
		wait(waittime);
		Roi.getCoordinates(tc1x,tc1y);
		wait(waittime);
		selectWindow("C2-"+targetname1);
		wait(waittime);
		Roi.getCoordinates(tc2x,tc2y);
		wait(waittime);
		selectWindow("C3-"+targetname1);
		wait(waittime);
		Roi.getCoordinates(tc3x,tc3y);
		wait(waittime);
		sx=Array.concat(sc1x,sc2x,sc3x);
		wait(waittime);
		sy=Array.concat(sc1y,sc2y,sc3y);
		wait(waittime);
		tx=Array.concat(tc1x,tc2x,tc3x);
		wait(waittime);
		ty=Array.concat(tc1y,tc2y,tc3y);
		wait(waittime);
		close("C1-"+sourcename1);
		wait(waittime);
		close("C2-"+sourcename1);
		wait(waittime);
		close("C3-"+sourcename1);
		wait(waittime);
		close("C1-"+targetname1);
		wait(waittime);
		close("C2-"+targetname1);
		wait(waittime);
		close("C3-"+targetname1);
		wait(waittime);
		selectWindow(sourcename1);
		wait(waittime);
		run("Split Channels");
		wait(waittime);
		selectWindow("C1-"+sourcename1);
		setLocation(320,240,320,240);
		wait(waittime);
		selectWindow("C2-"+sourcename1);
		setLocation(640,240,320,240);
		wait(waittime);
		selectWindow("C3-"+sourcename1);
		setLocation(960,240,320,240);
		wait(waittime);
		selectWindow(targetname1);
		wait(waittime);
		run("Split Channels");
		wait(waittime);
		selectWindow("C1-"+targetname1);
		setLocation(320,0,320,240);
		wait(waittime);
		selectWindow("C2-"+targetname1);
		setLocation(640,0,320,240);
		wait(waittime);
		selectWindow("C3-"+targetname1);
		setLocation(960,0,320,240);
		wait(waittime);
		selectWindow("C1-"+sourcename1);
		wait(waittime);
		makeSelection("point hybrid yellow small",sx,sy);
		wait(waittime);
		selectWindow("C2-"+sourcename1);
		wait(waittime);
		makeSelection("point hybrid yellow small",sx,sy);
		wait(waittime);
		selectWindow("C3-"+sourcename1);
		wait(waittime);
		makeSelection("point hybrid yellow small",sx,sy);
		wait(waittime);
		selectWindow("C1-"+targetname1);
		wait(waittime);
		makeSelection("point hybrid yellow small",tx,ty);
		wait(waittime);
		selectWindow("C2-"+targetname1);
		wait(waittime);
		makeSelection("point hybrid yellow small",tx,ty);
		wait(waittime);
		selectWindow("C3-"+targetname1);
		wait(waittime);
		makeSelection("point hybrid yellow small",tx,ty);
		wait(waittime);
		print("Starting Elastic Registration");
		wait(waittime);
		run("bUnwarpJ", "source_image=["+"C1-"+sourcename1+"] target_image=["+"C1-"+targetname1+"] registration=Mono image_subsample_factor=0 initial_deformation=[Very Coarse] final_deformation=Fine divergence_weight=0 curl_weight=0 landmark_weight=1 image_weight=0 consistency_weight=0 stop_threshold=0.01");
		wait(waittime);
		close("C1-"+sourcename1);
		wait(waittime);
		selectWindow("Registered Source Image");
		setLocation(320,240,320,240);
		wait(waittime);
		run("Slice Remover", "first=2 last=3 increment=1");
		setLocation(320,240,320,240);
		wait(waittime);
		rename("C1-"+sourcename1);
		wait(waittime);
		convertto16bit();
		wait(waittime);
		run("bUnwarpJ", "source_image=["+"C2-"+sourcename1+"] target_image=["+"C2-"+targetname1+"] registration=Mono image_subsample_factor=0 initial_deformation=[Very Coarse] final_deformation=Fine divergence_weight=0 curl_weight=0 landmark_weight=1 image_weight=0 consistency_weight=0 stop_threshold=0.01");
		wait(waittime);
		close("C2-"+sourcename1);
		wait(waittime);
		selectWindow("Registered Source Image");
		setLocation(640,240,320,240);
		wait(waittime);
		run("Slice Remover", "first=2 last=3 increment=1");
		setLocation(640,240,320,240);
		wait(waittime);
		rename("C2-"+sourcename1);
		wait(waittime);
		convertto16bit();
		wait(waittime);
		run("bUnwarpJ", "source_image=["+"C3-"+sourcename1+"] target_image=["+"C3-"+targetname1+"] registration=Mono image_subsample_factor=0 initial_deformation=[Very Coarse] final_deformation=Fine divergence_weight=0 curl_weight=0 landmark_weight=1 image_weight=0 consistency_weight=0 stop_threshold=0.01");
		wait(waittime);
		close("C3-"+sourcename1);
		wait(waittime);
		selectWindow("Registered Source Image");
		setLocation(960,240,320,240);
		wait(waittime);
		run("Slice Remover", "first=2 last=3 increment=1");
		setLocation(960,240,320,240);
		wait(waittime);
		rename("C3-"+sourcename1);
		wait(waittime);
		convertto16bit();
		wait(waittime);
		if (CM == true) {
		wait(waittime);
		run("Concatenate...", "title=C1 open image1=["+"C1-"+sourcename1+"] image2=["+"C1-"+targetname1+"]");
		wait(waittime);
		run("Stack Histogram Match", "referenceslice=["+Direction+"]");
		wait(waittime);
		run("Remove Slice Labels");
		wait(waittime);
		run("Stack to Images");
		wait(waittime);
		selectWindow("C1-0001");
		setLocation(320,240,320,240);
		wait(waittime);
		rename("C1-"+sourcename1);
		wait(waittime);
		selectWindow("C1-0002");
		setLocation(320,0,320,240);
		wait(waittime);
		rename("C1-"+targetname1);
		wait(waittime);
		close("C1");
		wait(waittime);
		close("Histogram-matched-C1");
		wait(waittime);
		run("Concatenate...", "title=C2 open image1=["+"C2-"+sourcename1+"] image2=["+"C2-"+targetname1+"]");
		wait(waittime);
		run("Stack Histogram Match", "referenceslice=["+Direction+"]");
		wait(waittime);
		run("Remove Slice Labels");
		wait(waittime);
		run("Stack to Images");
		wait(waittime);
		selectWindow("C2-0001");
		setLocation(640,240,320,240);
		wait(waittime);
		rename("C2-"+sourcename1);
		wait(waittime);
		selectWindow("C2-0002");
		setLocation(640,0,320,240);
		wait(waittime);
		rename("C2-"+targetname1);
		wait(waittime);
		close("C2");
		wait(waittime);
		close("Histogram-matched-C2");
		wait(waittime);
		run("Concatenate...", "title=C3 open image1=["+"C3-"+sourcename1+"] image2=["+"C3-"+targetname1+"]");
		wait(waittime);
		run("Stack Histogram Match", "referenceslice=["+Direction+"]");
		wait(waittime);
		run("Remove Slice Labels");
		wait(waittime);
		run("Stack to Images");
		wait(waittime);
		selectWindow("C3-0001");
		setLocation(960,240,320,240);
		wait(waittime);
		rename("C3-"+sourcename1);
		wait(waittime);
		selectWindow("C3-0002");
		setLocation(960,0,320,240);
		wait(waittime);
		rename("C3-"+targetname1);
		wait(waittime);
		close("C3");
		wait(waittime);
		close("Histogram-matched-C3");
		wait(waittime);
		}
		wait(waittime);
		run("Concatenate...", "open image1=["+"C1-"+sourcename1+"] image2=["+"C2-"+sourcename1+"] image3=["+"C3-"+sourcename1+"]");
		setLocation(1280,240,320,240);
		wait(waittime);
		run("Make Composite", "display=Composite");
		setLocation(1280,240,320,240);
		wait(waittime);
		convertto16bit();
		wait(waittime);
		PREPLABELS();
		wait(waittime);
		saveAs("Tiff", outputsourcedir+sourcename1+".tif");
		wait(waittime);
		close(sourcename1+".tif");
		wait(waittime);
		if (addborders > 0) {
		wait(waittime);
		run("Concatenate...", "open image1=["+"C1-"+targetname1+"] image2=["+"C2-"+targetname1+"] image3=["+"C3-"+targetname1+"]");
		setLocation(1280,0,320,240);
		wait(waittime);
		run("Make Composite", "display=Composite");
		setLocation(1280,0,320,240);
		wait(waittime);
		convertto16bit();
		wait(waittime);
		PREPLABELS();
		wait(waittime);
		saveAs("Tiff", outputtargetdir+targetname1+".tif");
		wait(waittime);
		close(targetname1+".tif");
		wait(waittime);
		} else {
		wait(waittime);
		close("C1-"+targetname1);
		wait(waittime);
		close("C2-"+targetname1);
		wait(waittime);
		close("C3-"+targetname1);
		wait(waittime);
		}
		} else {
		wait(waittime);
		close("C1-"+sourcename1);
		wait(waittime);
		close("C2-"+sourcename1);
		wait(waittime);
		close("C3-"+sourcename1);
		wait(waittime);
		close("C1-"+targetname1);
		wait(waittime);
		close("C2-"+targetname1);
		wait(waittime);
		close("C3-"+targetname1);
		wait(waittime);
		selectWindow(sourcename1);
		wait(waittime);
		smean=getValue("Mean");
		wait(waittime);
		run("Split Channels");
		wait(waittime);
		selectWindow("C1-"+sourcename1);
		setLocation(320,240,320,240);
		wait(waittime);
		selectWindow("C2-"+sourcename1);
		setLocation(640,240,320,240);
		wait(waittime);
		selectWindow("C3-"+sourcename1);
		setLocation(960,240,320,240);
		wait(waittime);
		selectWindow(targetname1);
		wait(waittime);
		tmean=getValue("Mean");
		wait(waittime);
		run("Split Channels");
		wait(waittime);
		selectWindow("C1-"+targetname1);
		setLocation(320,0,320,240);
		wait(waittime);
		selectWindow("C2-"+targetname1);
		setLocation(640,0,320,240);
		wait(waittime);
		selectWindow("C3-"+targetname1);
		setLocation(960,0,320,240);
		wait(waittime);
		selectWindow("C1-"+sourcename1);
		wait(waittime);
		makeSelection("point hybrid yellow small",sc01x,sc01y);
		wait(waittime);
		selectWindow("C2-"+sourcename1);
		wait(waittime);
		makeSelection("point hybrid yellow small",sc01x,sc01y);
		wait(waittime);
		selectWindow("C3-"+sourcename1);
		wait(waittime);
		makeSelection("point hybrid yellow small",sc01x,sc01y);
		wait(waittime);
		selectWindow("C1-"+targetname1);
		wait(waittime);
		makeSelection("point hybrid yellow small",tc01x,tc01y);
		wait(waittime);
		selectWindow("C2-"+targetname1);
		wait(waittime);
		makeSelection("point hybrid yellow small",tc01x,tc01y);
		wait(waittime);
		selectWindow("C3-"+targetname1);
		wait(waittime);
		makeSelection("point hybrid yellow small",tc01x,tc01y);
		wait(waittime);
		print("Starting Elastic Registration");
		wait(waittime);
		run("bUnwarpJ", "source_image=["+"C1-"+sourcename1+"] target_image=["+"C1-"+targetname1+"] registration=Mono image_subsample_factor=0 initial_deformation=[Very Coarse] final_deformation=Fine divergence_weight=0 curl_weight=0 landmark_weight=1 image_weight=0 consistency_weight=0 stop_threshold=0.01");
		wait(waittime);
		close("C1-"+sourcename1);
		wait(waittime);
		selectWindow("Registered Source Image");
		setLocation(320,240,320,240);
		wait(waittime);
		run("Slice Remover", "first=2 last=3 increment=1");
		setLocation(320,240,320,240);
		wait(waittime);
		rename("C1-"+sourcename1);
		wait(waittime);
		convertto16bit();
		wait(waittime);
		run("bUnwarpJ", "source_image=["+"C2-"+sourcename1+"] target_image=["+"C2-"+targetname1+"] registration=Mono image_subsample_factor=0 initial_deformation=[Very Coarse] final_deformation=Fine divergence_weight=0 curl_weight=0 landmark_weight=1 image_weight=0 consistency_weight=0 stop_threshold=0.01");
		wait(waittime);
		close("C2-"+sourcename1);
		wait(waittime);
		selectWindow("Registered Source Image");
		setLocation(640,240,320,240);
		wait(waittime);
		run("Slice Remover", "first=2 last=3 increment=1");
		setLocation(640,240,320,240);
		wait(waittime);
		rename("C2-"+sourcename1);
		wait(waittime);
		convertto16bit();
		wait(waittime);
		run("bUnwarpJ", "source_image=["+"C3-"+sourcename1+"] target_image=["+"C3-"+targetname1+"] registration=Mono image_subsample_factor=0 initial_deformation=[Very Coarse] final_deformation=Fine divergence_weight=0 curl_weight=0 landmark_weight=1 image_weight=0 consistency_weight=0 stop_threshold=0.01");
		wait(waittime);
		close("C3-"+sourcename1);
		wait(waittime);
		selectWindow("Registered Source Image");
		setLocation(960,240,320,240);
		wait(waittime);
		run("Slice Remover", "first=2 last=3 increment=1");
		setLocation(960,240,320,240);
		wait(waittime);
		rename("C3-"+sourcename1);
		wait(waittime);
		convertto16bit();
		wait(waittime);
		if (RMF == true && (tmean > 0 && smean == 0)) {
		wait(waittime);
		close("C1-"+sourcename1);
		wait(waittime);
		close("C2-"+sourcename1);
		wait(waittime);
		close("C3-"+sourcename1);
		wait(waittime);
		run("Concatenate...", "open image1=["+"C1-"+targetname1+"] image2=["+"C2-"+targetname1+"] image3=["+"C3-"+targetname1+"]");
		setLocation(1280,0,320,240);
		wait(waittime);
		run("Make Composite", "display=Composite");
		setLocation(1280,0,320,240);
		wait(waittime);
		PREPLABELS();
		wait(waittime);
		if (addborders > 0) {
		wait(waittime);
		saveAs("Tiff", outputtargetdir+targetname1+".tif");
		wait(waittime);
		}
		wait(waittime);
		saveAs("Tiff", outputsourcedir+sourcename1+".tif");
		wait(waittime);
		close(sourcename1+".tif");
		wait(waittime);
		} else if ( RMF == true && (tmean == 0 && smean > 0)) {
		wait(waittime);
		run("Concatenate...", "open image1=["+"C1-"+sourcename1+"] image2=["+"C2-"+sourcename1+"] image3=["+"C3-"+sourcename1+"]");
		setLocation(1280,240,320,240);
		wait(waittime);
		run("Make Composite", "display=Composite");
		setLocation(1280,240,320,240);
		wait(waittime);
		PREPLABELS();
		wait(waittime);
		if (addborders > 0) {
		wait(waittime);
		saveAs("Tiff", outputtargetdir+targetname1+".tif");
		wait(waittime);
		}
		wait(waittime);
		saveAs("Tiff", outputsourcedir+sourcename1+".tif");
		wait(waittime);
		close(sourcename1+".tif");
		wait(waittime);
		close("C1-"+targetname1);
		wait(waittime);
		close("C2-"+targetname1);
		wait(waittime);
		close("C3-"+targetname1);
		wait(waittime);
		} else {
		wait(waittime);
		run("Concatenate...", "open image1=["+"C1-"+sourcename1+"] image2=["+"C2-"+sourcename1+"] image3=["+"C3-"+sourcename1+"]");
		setLocation(1280,240,320,240);
		wait(waittime);
		run("Make Composite", "display=Composite");
		setLocation(1280,240,320,240);
		wait(waittime);
		PREPLABELS();
		wait(waittime);
		saveAs("Tiff", outputsourcedir+sourcename1+".tif");
		wait(waittime);
		close(sourcename1+".tif");
		wait(waittime);
		if (addborders > 0) {
		wait(waittime);
		run("Concatenate...", "open image1=["+"C1-"+targetname1+"] image2=["+"C2-"+targetname1+"] image3=["+"C3-"+targetname1+"]");
		setLocation(1280,0,320,240);
		wait(waittime);
		run("Make Composite", "display=Composite");
		setLocation(1280,0,320,240);
		wait(waittime);
		PREPLABELS();
		wait(waittime);
		saveAs("Tiff", outputtargetdir+targetname1+".tif");
		wait(waittime);
		close(targetname1+".tif");
		wait(waittime);
		} else {
		wait(waittime);
		close("C1-"+targetname1);
		wait(waittime);
		close("C2-"+targetname1);
		wait(waittime);
		close("C3-"+targetname1);
		wait(waittime);
		}
		}
}
	print("\\Clear");
	wait(500);
	close("*");
	wait(waittime);
	call("java.lang.System.gc");
	wait(waittime);
	run("Collect Garbage");
	wait(waittime);
	while (nImages()>0) {
            selectImage(nImages());  
            wait(waittime);
            run("Close");
	}
}

call("java.lang.System.gc");
wait(waittime);
beep();
wait(waittime);
waitForUser("The registration macro is finished.");

//function IMPORT() {
//
//}

function SIFT(sourcename,targetname,steps) {
run("Extract SIFT Correspondences", "source_image="+sourcename+" target_image="+targetname+" initial_gaussian_blur=1.60 steps_per_scale_octave="+steps+" minimum_image_size=64 maximum_image_size=1024 feature_descriptor_size=4 feature_descriptor_orientation_bins=8 closest/next_closest_ratio=0.92 filter maximal_alignment_error=25 minimal_inlier_ratio=0.05 minimal_number_of_inliers=20 expected_transformation=Affine");
}

function PREPLABELS() {
setSlice(3);
wait(waittime);
run("Set Label...", "label=Blue");
wait(waittime);
setSlice(2);
wait(waittime);
run("Set Label...", "label=Green");
wait(waittime);
setSlice(1);
wait(waittime);
run("Set Label...", "label=Red");
wait(waittime);
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
		wait(waittime);
		run("Multiply...", "value=256.000");
		wait(waittime);
		setMinAndMax(0, 65535);
		wait(waittime);
		call("ij.ImagePlus.setDefault16bitRange", 16);
		wait(waittime);
		setSlice(2);
		wait(waittime);
		setMinAndMax(0,65535);
		wait(waittime);
		call("ij.ImagePlus.setDefault16bitRange", 16);
		wait(waittime);
		setSlice(3);
		wait(waittime);
		setMinAndMax(0,65535);
		wait(waittime);
		call("ij.ImagePlus.setDefault16bitRange", 16);
		wait(waittime);
		} else if (bitDepth == 32){
		setMinAndMax(0, 65535);
		wait(waittime);
		call("ij.ImagePlus.setDefault16bitRange", 16);
		wait(waittime);
		run("16-bit");
		wait(waittime);
		}	
		wait(waittime);
		run("Remove Slice Labels");
				
}
