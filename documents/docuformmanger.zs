// Document manager's form management
// Knockoff from gpFormStore but modified to tie-up to folderstructure ID instead of individual ID

flag1_fieldname = flag2_fieldname = "";
glob_selected_form = glob_selected_form_user = "";
last_list_type = 0;

Object getFormStorage_rec(String iwhat)
{
	sqlstm = "select * from elb_formstorage where origid=" + iwhat;
	return sqlhand.gpSqlFirstRow(sqlstm);
}

void showFormStorageMetadata(String iwhat) // knockoff gpformstore.zul
{
	fstrec = getFormStorage_rec(iwhat);
	if(fstrec == null) return;

	fkepid = fstrec.get("formkeeper_id");

	// load form-xml from formkeeper
	fmobj = sqlhand.getFormKeeper_rec(fkepid.toString());
	if(fmobj == null) { gui.showMessageBox("ERR: Cannot load XML-form definitions"); return; }

	formxml = sqlhand.clobToString(fmobj.get("xmlformstring"));
	glob_formmaker = new vicFormMaker(formholder,JN_linkcode(),formxml);
	glob_formmaker.generateForm();

	forminputs = sqlhand.clobToString(fstrec.get("inputs_value"));
	if(forminputs != null) glob_formmaker.populateFormValues(forminputs);
}

class formsstorage_onSelect implements org.zkoss.zk.ui.event.EventListener
{
	public void onEvent(Event event) throws UiException
	{
		isel = forms_lb.getSelectedItem();
		glob_selected_form = lbhand.getListcellItemLabel(isel,0);
		glob_selected_form_user = lbhand.getListcellItemLabel(isel,3);
		showFormStorageMetadata(glob_selected_form);
		/*
		formdesc = lbhand.getListcellItemLabel(isel,2);
		form_title_tb.setValue(formdesc); // form-title textbox
		form_origid.setValue(glob_selected_form);
		*/
	}
}
fmclicker = new formsstorage_onSelect();

// knockoff from gpformstorage. modified
// itype: 1=just load, 2=search text
void listFormStorage(int itype, String iformid)
{
Object[] formslist_headers =
{
	new listboxHeaderWidthObj("ID#",true,"40px"),
	new listboxHeaderWidthObj("Dated",true,"60px"),
	new listboxHeaderWidthObj("Form.Description",true,""),
	new listboxHeaderWidthObj("User",true,"60px"),
	new listboxHeaderWidthObj("FLAG1",true,"70px"),
	new listboxHeaderWidthObj("FLAG2",true,"70px"),
};

	last_list_type = itype;
	Listbox newlb = lbhand.makeVWListbox_Width(formslist_holder, formslist_headers, "forms_lb", 20);
	setxt = kiboo.replaceSingleQuotes(searchtext_tb.getValue());

	inp = "";
	chkinps = false;
	if(!flag1_fieldname.equals("") || !flag2_fieldname.equals(""))
	{
		inp = ",inputs_value";
		chkinps = true;
	}

	sqlstm = "select origid,form_title,updateby,lastupdate" + inp + " from elb_formstorage " +
	"where formparent_id='" +  iformid + "'";

	if(itype == 2) sqlstm += " and (inputs_value like '%" + setxt + "%' or form_title like '%" + setxt + "%') ";
	sqlstm += " order by origid desc";

	screcs = sqlhand.gpSqlGetRows(sqlstm);
	if(screcs.size() == 0) return;
	newlb.setMold("paging");
	newlb.addEventListener("onSelect", fmclicker);
	ArrayList kabom = new ArrayList();
	String[] fl = { "origid", "lastupdate", "form_title", "updateby" };
	for(dpi : screcs)
	{
		ngfun.popuListitems_Data(kabom,fl,dpi);
		if(chkinps) // need to put extra FLAG fields to list
		{
			if(dpi.get("inputs_value") != null)
			{
				inps = sqlhand.clobToString(dpi.get("inputs_value"));
				irecs = inps.split("::");
				f1s = f2s = "";
				try {
					for(int i=0; i<irecs.length; i++)
					{
						tmpstr = irecs[i];
						iparts = tmpstr.split("\\|"); // split the field and data parts
						fieldpart = iparts[0].replace("\"","");
						datapart = iparts[1].replace("\"","");
						if(fieldpart.equals(flag1_fieldname)) f1s = datapart;
						if(fieldpart.equals(flag2_fieldname)) f2s = datapart;
					}
				} catch (Exception e) {}
				kabom.add(f1s);
				kabom.add(f2s);
			}
		}
		lbhand.insertListItems(newlb,kiboo.convertArrayListToStringArray(kabom),"false","");
		kabom.clear();
	}
}

void populateFormsList(Div idiv, String lbid)
{
Object[] formslist_headers = 
{
	new listboxHeaderWidthObj("No.",true,"40px"),
	new listboxHeaderWidthObj("Form",true,""),
	new listboxHeaderWidthObj("User",true,""),
};
	Listbox newlb = lbhand.makeVWListbox_Width(idiv, formslist_headers, lbid, 20);
	sqlstm = "select origid,form_name,created_by from elb_formkeeper order by origid desc";
	screcs = sqlhand.gpSqlGetRows(sqlstm);
	if(screcs.size() == 0) return;
	newlb.setMold("paging");
	//newlb.addEventListener("onSelect", fmlisclik );
	ArrayList kabom = new ArrayList();
	String[] fl = { "origid","form_name","created_by" };
	for(d : screcs)
	{
		ngfun.popuListitems_Data(kabom,fl,d);
		lbhand.insertListItems(newlb,kiboo.convertArrayListToStringArray(kabom),"false","");
		kabom.clear();
	}
}

void insertFormTypeToFolderstruct(String ijn, String iformid)
{
	todate =  kiboo.todayISODateTimeString();

	sqlstm = "insert into elb_formstorage (formparent_id,inputs_value,formkeeper_id,form_title,lastupdate,updateby,thisform_parent) values " +
	" ('" + ijn + "',''," + iformid + ",'NEW BLANK FORM #" + iformid + "','" + todate + "','" +
	useraccessobj.username + "',0)";

	sqlhand.gpSqlExecuter(sqlstm);
	listFormStorage(last_list_type, JN_linkcode()); // refresh -- need to code for other moduls

	//alert(ijn + " :: " + iformid + " :: " + sqlstm);
}