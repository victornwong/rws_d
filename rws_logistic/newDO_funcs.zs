import org.victor.*;
// Genaral funcs for newDOmanager

String[] itm_colws = { "30px","",                "60px" };
String[] itm_colls = { ""    ,"Item description","Qty"  };

class tbnulldrop implements org.zkoss.zk.ui.event.EventListener
{
	public void onEvent(Event event) throws UiException
	{
	}
}
textboxnulldrop = new tbnulldrop();

// Get DOs tied to Job
String getJob_linkDO(int ijb)
{
	retv = "";
	sqlstm = "select id from deliveryordermaster where job_id=" + ijb.toString();
	r = sqlhand.gpSqlGetRows(sqlstm);
	if(r.size() != 0)
	{
		for(d : r)
		{
			retv += d.get("id").toString() + ",";
		}
		try { retv = retv.substring(0,retv.length()-1); } catch (Exception e) {}
	}
	return retv;
}

Object getnewDO_rec(String iwhat)
{
	sqlstm = "select * from deliveryordermaster where id=" + iwhat;
	return sqlhand.gpSqlFirstRow(sqlstm);
}

void saveDO_items(String ido)
{
	try
	{
		sqlstm = "delete from deliveryorder where dono='" + ido + "';";
		sqlhand.gpSqlExecuter(sqlstm); // remove all prev DO items first before saving new ones

		sqlstm = "";
		jk = items_rows.getChildren().toArray();
		ArrayList itms = new ArrayList();

		for(i=0;i<jk.length;i++)
		{
			ki = jk[i].getChildren().toArray();
			ti = kiboo.replaceSingleQuotes( ki[1].getValue().trim() ); // item
			tq = "1";
			try { kk = Integer.parseInt(kiboo.replaceSingleQuotes( ki[2].getValue().trim() ) ); tq = kk.toString(); }
			catch (Exception e) {}

			sqlstm += "insert into deliveryorder (dono,description,quantity) values ('" + ido + "','" + ti + "'," + tq + ");";
		}
		if(!sqlstm.equals("")) sqlhand.gpSqlExecuter(sqlstm);

	} catch (Exception e) {}
}

void showDO_items(String ido)
{
	if(items_holder.getFellowIfAny("items_grid") != null) items_grid.setParent(null);
	ngfun.checkMakeGrid(itm_colws,itm_colls,items_holder,"items_grid","items_rows","background:#97b83a","",false);

	sqlstm = "select description,quantity from deliveryorder where dono='" + ido + "';";
	r = sqlhand.gpSqlGetRows(sqlstm);
	if(r.size() == 0) return;

	for(d : r)
	{
		irow = gridhand.gridMakeRow("","","",items_rows);
		ngfun.gpMakeCheckbox(irow,"","","");
		lk = ngfun.gpMakeTextbox(irow,"",d.get("description"),"font-size:9px;","99%",textboxnulldrop);
		lk.setMultiline(true);
		ngfun.gpMakeTextbox(irow,"", GlobalDefs.nf0.format(d.get("quantity")),"font-size:9px;","60%",textboxnulldrop);
	}
}

void showDO_meta(String ido)
{
	r = getnewDO_rec(ido);
	if(r == null) { guihand.showMessageBox("ERR: cannot access DO table.."); return; }

	Object[] jkl = { customername, d_code, d_shipaddress1, d_shipaddress2, d_shipaddress3, d_shippingcontact, d_shippingphone, d_remark, d_transporter, d_airwaybill };
	String[] fl = { "Name", "Code", "ShipAddress1", "ShipAddress2", "ShipAddress3", "ShippingContact", "ShippingPhone", "Remark", "transporter", "airwaybill" };

	ngfun.populateUI_Data(jkl,fl,r);
	showDO_items(ido);
}

Object[] dolbhds =
{
	new listboxHeaderWidthObj("RDO",true,"60px"),
	new listboxHeaderWidthObj("Date",true,"70px"),
	new listboxHeaderWidthObj("Customer",true,""),
	new listboxHeaderWidthObj("JobId",true,"90px"),
	new listboxHeaderWidthObj("User",true,"70px"),
};

class dolbClick implements org.zkoss.zk.ui.event.EventListener
{
	public void onEvent(Event event) throws UiException
	{
		isel = event.getReference();
		glob_sel_do = lbhand.getListcellItemLabel(isel,0);
		global_selected_customername = lbhand.getListcellItemLabel(isel,2);
		showDO_meta(glob_sel_do);
	}
}
dolbclkier = new dolbClick();

// itype: 1=by date and search text, 2=by DO
void showDOList(int itype)
{
	last_showdo_type = itype;

	st = kiboo.replaceSingleQuotes(searhtxt_tb.getValue().trim());
	sdate = kiboo.getDateFromDatebox(startdate);
	edate = kiboo.getDateFromDatebox(enddate);
	doid = kiboo.replaceSingleQuotes(doid_tb.getValue().trim());

	Listbox newlb = lbhand.makeVWListbox_Width(do_holder, dolbhds, "do_lb", 3);

	sqlstm = "select top 200 id,entrydate,name,user1,job_id from DeliveryOrderMaster ";

	switch(itype)
	{
		case 1:
			sqlstm += "where entrydate between '" + sdate + " 00:00:00' and '" + edate + " 23:59:00' and name like '%" + st + "%'";
			break;
		case 2:
			sqlstm += "where id=" + doid;
			break;
	}

	sqlstm += " order by entrydate";

	rcs = sqlhand.gpSqlGetRows(sqlstm);
	if(rcs.size() == 0) return;
	newlb.setRows(20); newlb.setMold("paging");
	newlb.addEventListener("onSelect", dolbclkier);
	ArrayList kabom = new ArrayList();
	String[] fl = { "id", "entrydate", "name", "job_id", "user1" };
	for(d : rcs)
	{
		ngfun.popuListitems_Data(kabom,fl,d);
		lbhand.insertListItems(newlb,kiboo.convertArrayListToStringArray(kabom),"false","");
		kabom.clear();
	}
}

void chopInsertJobIntoDO(String iwhat)
{
	jrec = getRWJob_rec(iwhat);
	if(jrec == null)
	{
		guihand.showMessageBox("ERR: cannot access job database...");
		return;
	}

	// get/set job metadata into DO
	adrsp = jrec.get("deliver_address").split("\n");
	try { d_shipaddress1.setValue(adrsp[0]); } catch (Exception e) {}
	try { d_shipaddress2.setValue(adrsp[1]); } catch (Exception e) {}
	try { d_shipaddress3.setValue(adrsp[2]); } catch (Exception e) {}
	d_shippingcontact.setValue( jrec.get("contact") );
	d_shippingphone.setValue( jrec.get("contact_tel") );
	d_remark.setValue( jrec.get("notes") );

	sqlstm = "delete from deliveryorder where dono='" + glob_sel_do + "';";
	sqlhand.gpSqlExecuter(sqlstm); // remove all DO items first before importing new ones

	// get 'em job items
	if(items_holder.getFellowIfAny("items_grid") != null) items_grid.setParent(null);
	ngfun.checkMakeGrid(itm_colws,itm_colls,items_holder,"items_grid","items_rows","background:#97b83a","",false);

	items = sqlhand.clobToString( jrec.get("items") ).split("::");
	qtys = jrec.get("qtys").split("::");
	//colors = jrec.get("colors").split("::");
	isql = "";

	for(i=0;i<items.length;i++)
	{
		irow = gridhand.gridMakeRow("","","",items_rows);

		ngfun.gpMakeCheckbox(irow,"","","");
		//ngfun.gpMakeLabel(irow,"",(i+1).toString() + ".", "font-size:14px;font-weight:bold;");

		itm = "";
		try { itm = items[i]; } catch (Exception e) {}

		isql += "insert into deliveryorder (dono,description,quantity) values ('" + glob_sel_do + "','" + itm + "',";

		lk = ngfun.gpMakeTextbox(irow,"",itm,"font-size:9px;","99%",textboxnulldrop);
		lk.setMultiline(true);

		qty = "";
		try { qty = qtys[i]; } catch (Exception e) {}
		ngfun.gpMakeTextbox(irow,"",qty,"font-size:9px;","60%",textboxnulldrop);

		isql += qty + ");";
	}

	isql += "update deliveryordermaster set job_id=" + iwhat + " where id=" + glob_sel_do + ";";
	sqlhand.gpSqlExecuter(isql);
}

Object[] jobdohds =
{
	new listboxHeaderWidthObj("Job",true,"70px"),
	new listboxHeaderWidthObj("Date",true,"70px"),
	new listboxHeaderWidthObj("ETA",true,"70px"),
	new listboxHeaderWidthObj("ETD",true,"70px"),
	new listboxHeaderWidthObj("DOs",true,"70px"),
};

class jobdodclick implements org.zkoss.zk.ui.event.EventListener
{
	public void onEvent(Event event) throws UiException
	{
		isel = event.getTarget();

		if(Messagebox.show("Importing details from job.. will overwrite everything" , "Are you sure?",
			Messagebox.YES | Messagebox.NO, Messagebox.QUESTION) !=  Messagebox.YES) return;

		chopInsertJobIntoDO(lbhand.getListcellItemLabel(isel,0));
	}
}
jobdodoubleclik = new jobdodclick();

void showJobsByCustomer()
{
	sqlstm = "select origid, datecreated, eta, etd from rw_jobs where customer_name='" + global_selected_customername + "' ";
	sqlstm += "order by origid desc";

	Listbox newlb = lbhand.makeVWListbox_Width(jobsdolb_holder, jobdohds, "jobsdo_lb", 10);
	rcs = sqlhand.gpSqlGetRows(sqlstm);
	if(rcs.size() == 0) return;
	//newlb.addEventListener("onSelect", jobdodoubleclik);
	ArrayList kabom = new ArrayList();
	String[] fl = { "origid", "datecreated", "eta", "etd" };
	for(d : rcs)
	{
		ngfun.popuListitems_Data(kabom,fl,d);
		kabom.add( getJob_linkDO(d.get("origid")) );
		lbhand.insertListItems(newlb,kiboo.convertArrayListToStringArray(kabom),"false","");
		kabom.clear();
	}
	lbhand.setDoubleClick_ListItems(newlb,jobdodoubleclik);
}
