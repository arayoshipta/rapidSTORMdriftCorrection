//rapidSTORM reconstructor with drift correction by fiducial
//Author: Yoshiyuki Arai
//Data: 2013.08.05
macro rapidSTROMreconstructor {
	// read rapidSTORM text data
	rapidSTORMfile = File.openDialog("Select rapidSTORM text data");
	rapidSTORMtxt = File.openAsString(rapidSTORMfile);
	datatxt = split(rapidSTORMtxt,"\n"); //split each line in datatxt array
	//hdr = split(datatxt[0]);

	// Dialog for getting parameters
	Dialog.create("Input parameters");
	Dialog.addNumber("width of image (um)",16.575);
	Dialog.addNumber("height of image (um)",16.575);
	Dialog.addNumber("superresolution image pixels size (nm)",10);
	Dialog.addCheckbox("Do drift correction",false);
	Dialog.show();
	w=Dialog.getNumber();
	h=Dialog.getNumber();
	ps=Dialog.getNumber();
	dc=Dialog.getCheckbox();

	//decleare x,y,frame array for drift data
	dx=newArray(datatxt.length);
	dy=newArray(datatxt.length);
	df=newArray(datatxt.length);
	if (dc) {
		// read drift text data
		driftfile = File.openDialog("Select drift text data by PTA");
		drifttxt = File.openAsString(driftfile);
		driftdatatxt = split(drifttxt,"\n");
		//drifthdr = split(datatxt[0]);
		for(i=1;i<driftdatatxt.length;i++) {
			dline = split(driftdatatxt[i]," "); // split each column by " "
			if (i == 1 ) { // initial values are used for fiducial point
				idx=parseFloat(dline[0]); // get initial value as reference
				idy=parseFloat(dline[1]);
				df[0]=parseInt(dline[2]);
			}
			if (i != 1) {
				dx[i-1]=parseFloat(dline[0])-idx; // put drift x,y subtracted data 
				dy[i-1]=parseFloat(dline[1])-idy;
				df[i-1]=parseInt(dline[2]);
			}
			//print("i-1"+(i-1)+":dx="+dx[i-1]+", dy="+dy[i-1]+"df="+df[i-1]);
		}
	}
	newImage("STORM","16-bit black",round(w*1000/ps),round(h*1000/ps),1); // create image
	run("Set Scale...", "distance=1 known="+ps+" pixel=1 unit=nm"); // set scale
	cnt=0; // counter for drfit-correction data
	for(i=1;i<(datatxt.length);i++) {
		line=split(datatxt[i]," ");
		x=parseFloat(line[0]);
		y=parseFloat(line[1]);
		f=parseInt(line[2]);
		sx=x/ps; // interpolate raw data in pixels
		sy=y/ps;
		//print("f="+f+",df="+df[cnt]+",cnt="+cnt);
		if(dc && df[cnt]==f) {
			sx=sx-dx[f]/ps; // drift correction
			sy=sy-dy[f]/ps;
			//print(i+" frame:"+df[i-1]+"dx="+dx[i-1]+",dy="+dy[i-1]);
			val = getPixel(round(sx),round(sy)); // get pixel value
			setPixel(round(sx),round(sy),val+1); // add pixel value
		} else if (dc && df[cnt]<f) {
			cnt++; // if df[cnt] value is less than f, increase cnt value
		} else if (!dc) {
			val = getPixel(round(sx),round(sy)); // get pixel value
			setPixel(round(sx),round(sy),val+1); // add pixel value
		}

	}
	run("Enhance Contrast", "saturated=0.35"); // auto enhance
}
