import org.victor.*;

// Funcs used in whPlayJobSheet_v1

Object getJobpicklist_rec_byjob(String iwhat)
{
	sqlstm = "select * from rw_jobpicklist where parent_job=" + iwhat;
	return sqlhand.gpSqlFirstRow(sqlstm);
}

// Get loca/pallets by item name. HARDCODED some conditions
String locaPallet_byItem(String itm)
{
	retval = "";

	sqlstm = "select distinct pallet, sum(qty) as instk from partsall_0 where " +
	"name='" + itm + "' " +
	"and name not like '(DO NOT%' and name not like '%EIS%' " +
	"and pallet not like 'EIS%' and pallet<>'PROD' and pallet<>'WH PALLET' and pallet<>'OUT' " +
	"group by pallet having sum(qty) > 0";

	r = sqlhand.rws_gpSqlGetRows(sqlstm);
	if(r.size() == 0) return "";
	for(d : r)
	{
		retval += d.get("pallet") + "(" + GlobalDefs.nf0.format(d.get("instk")) + "), ";
	}
	try { retval = retval.substring(0,retval.length() - 2); } catch (Exception e) {}
	return retval;
}

boolean saveScannedTags()
{
	try
	{
		jnt = kiboo.replaceSingleQuotes(j_extranotes.getValue().trim());
		itms = qtys = atgs = "";
		jk = pl_rows.getChildren().toArray();
		for(i=0;i<jk.length;i++)
		{
			ki = jk[i].getChildren().toArray();
			itms += kiboo.replaceSingleQuotes( ki[2].getValue().trim().replaceAll("~"," ") ) + "~";
			qtys += kiboo.replaceSingleQuotes( ki[3].getValue().trim().replaceAll("~"," ") ) + "~";
			atgs += kiboo.replaceSingleQuotes( ki[4].getValue().trim().replaceAll("~"," ") ) + "~";
		}

		try { itms = itms.substring(0,itms.length()-1); } catch (Exception e) {}
		try { qtys = qtys.substring(0,qtys.length()-1); } catch (Exception e) {}
		try { atgs = atgs.substring(0,atgs.length()-1); } catch (Exception e) {}

		sqlstm = "if not exists (select 1 from rw_jobpicklist where parent_job=" + glob_sel_job + ") " +
		"insert into rw_jobpicklist (parent_job,username,datecreated,pl_items,pl_qty,pstatus,extranotes,pl_asset_tags) values " +
		"(" + glob_sel_job + ",'" + unm + "','" + todaydate + "','" + itms + "','" + qtys + "','DRAFT','" + jnt + "','" + atgs + "') " +
		"else " +
		"update rw_jobpicklist set pl_items='" + itms + "', pl_qty='" + qtys + "', pl_asset_tags='" + atgs + "', extranotes='" + jnt + "' where parent_job=" + glob_sel_job + ";";

		sqlhand.gpSqlExecuter(sqlstm);

		return true;

	} catch (Exception e) { return false; }
}

// knock-off from wopAsschecker.zul
void checkScannedTags(String itemname, String iatgs)
{
Object[] wpshd =
{
	new listboxHeaderWidthObj("AssetTag",true,"70px"),
	new listboxHeaderWidthObj("S/Num",true,"70px"),
	new listboxHeaderWidthObj("Desc",true,"70px"),
	new listboxHeaderWidthObj("Brand",true,"70px"),
	new listboxHeaderWidthObj("Model",true,""),
	new listboxHeaderWidthObj("Grd",true,"40px"),
	new listboxHeaderWidthObj("PalletNo",true,"40px"),
	new listboxHeaderWidthObj("Type",true,"40px"),
};

	mwin = ngfun.vMakeWindow(winsholder,"Check scanned tags : " + itemname.trim(),"0","center","500px","");
	kdiv = new Div();
	kdiv.setParent(mwin);
	Listbox newlb = lbhand.makeVWListbox_Width(kdiv, wpshd, "fndassets_lb", 5);

	tgs = iatgs.trim().split("\n");
	asts = "";
	for(i=0;i<tgs.length;i++)
	{
		asts += "'" + tgs[i].trim() + "',";
	}
	try { asts = asts.substring(0,asts.length()-1); } catch (Exception e) {}

	kk = "where ltrim(rtrim(s.code2)) in (" + asts + ") order by s.code2 desc;";
	if(itype == 2) kk = "where ltrim(rtrim(s.code)) in (" + asts + ") order by s.code desc;";

	sqlstm = "select s.name, s.code, s.code2, si.brandyh, si.modelyh, si.gradeyh, si.itemtypeyh, w.name as palletno " +
	"from mr001 s left join u0001 si on si.extraid = s.eoff " +
	"left join mr003 w on w.masterid = si.palletnoyh " + kk;
	
	ats = sqlhand.rws_gpSqlGetRows(sqlstm);
	if(ats.size() == 0) return;
	newlb.setRows(20); newlb.setMold("paging");
	//newlb.setMultiple(true); newlb.setCheckmark(true);
	ArrayList kabom = new ArrayList();
	String[] fl = { "code2", "code", "name", "brandyh", "modelyh", "gradeyh", "palletno", "itemtypeyh" };
	for(d : ats)
	{
		ngfun.popuListitems_Data(kabom,fl,d);
		lbhand.insertListItems(newlb,kiboo.convertArrayListToStringArray(kabom),"false","");
		kabom.clear();
	}

	ngfun.gpMakeLabel(kdiv,"","Scanned: " + tgs.length.toString(),"");
	ngfun.gpMakeSeparator(2,"",kdiv);
	ngfun.gpMakeLabel(kdiv,"","Found: " + ats.size().toString(),"");
}

// iwhat: job id
void genWH_picklist(String iwhat)
{
	jrec = rwsqlfun.getRWJob_rec(iwhat);
	if(jrec == null) return;
	jnum = jrec.get("origid").toString();
	jpl = getJobpicklist_rec_byjob(jnum);

	startadder = 1;
	rowcount = 1 + startadder;

	templatefn = "rwimg/jobpicklist_temp_1.xls";
	inpfn = session.getWebApp().getRealPath(templatefn);
	InputStream inp = new FileInputStream(inpfn);
	HSSFWorkbook excelWB = new HSSFWorkbook(inp);
	evaluator = excelWB.getCreationHelper().createFormulaEvaluator();
	HSSFSheet sheet = excelWB.getSheetAt(0);
	//HSSFSheet sheet = excelWB.createSheet("THINGS");

	Font wfont = excelWB.createFont();
	wfont.setFontHeightInPoints((short)8);
	wfont.setFontName("Arial");

	excelInsertString(sheet,0,1, "RWMS Job ID: " + jnum );
	excelInsertString(sheet,1,1, "Customer: " + jrec.get("customer_name") );
	excelInsertString(sheet,3,1, kiboo.checkNullString(jpl.get("extranotes")) );

	excelInsertString(sheet,0,3, "Date: " + GlobalDefs.dtf2.format(jrec.get("datecreated")) );
	excelInsertString(sheet,1,3, "ETD: " + GlobalDefs.dtf2.format(jrec.get("etd")) );
	excelInsertString(sheet,2,3, "JobType: " + kiboo.checkNullString(jrec.get("jobtype")) );
	excelInsertString(sheet,3,3, "OrderType: " + kiboo.checkNullString(jrec.get("order_type")) );

	CellStyle st3 =  excelWB.createCellStyle();
	st3.setFillForegroundColor(HSSFColor.GREY_40_PERCENT.index);
	st3.setFillPattern(HSSFCellStyle.SOLID_FOREGROUND);
	st3.setWrapText(true);
	//st3.setAlignment(CellStyle.ALIGN_CENTER);
	st3.setBorderLeft(CellStyle.BORDER_THIN);
	st3.setBorderRight(CellStyle.BORDER_THIN);
	st3.setBorderBottom(CellStyle.BORDER_THIN);
	st3.setFont(wfont);

	CellStyle st4 =  excelWB.createCellStyle();
	st4.cloneStyleFrom(st3);
	st4.setFillPattern(HSSFCellStyle.NO_FILL);

	// loop print the req items
	lnc = 1;
	itms = sqlhand.clobToString(jpl.get("pl_items")).split("~");
	qtys = sqlhand.clobToString(jpl.get("pl_qty")).split("~");

	for(i=0; i<itms.length; i++)
	{
		excelInsertString(sheet,5+i,0, lnc.toString() + ".");
		excelInsertString(sheet,5+i,1, itms[i]);
		excelInsertString(sheet,5+i,2, qtys[i]);
		excelInsertString(sheet,5+i,3, locaPallet_byItem(itms[i]) );
		lnc++;
		POI_SetCellStyleRange(sheet,st4,5+i,0,4);
	}

	tfname = iwhat + "_whpl.xls";
	outfn = session.getWebApp().getRealPath("tmp/" + tfname );
	FileOutputStream fileOut = new FileOutputStream(outfn);
	excelWB.write(fileOut);
	fileOut.close();

	downloadFile(kasiexport,tfname,outfn);

}

