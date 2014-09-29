import org.victor.*;
// General funcs for goodsReceive_v2.zul
// 

String[] scanitems_colws = { "30px", "",          "180px",     "100px", "40px" };
String[] scanitems_collb = { "",     "Item name", "Asset tag", "Serial","Qty" };


Object getGRN_rec(String iwhat)
{
	sqlstm = "select * from rw_grn where origid=" + iwhat;
	return sqlhand.gpSqlFirstRow(sqlstm);
}

void hidereset_workarea()
{
	glob_sel_grn = glob_sel_stat = "";
	grnmeta_holder.setVisible(false);
	grnitems_workarea.setVisible(false);
}

class tbnulldrop implements org.zkoss.zk.ui.event.EventListener
{	public void onEvent(Event event) throws UiException	{} }
textboxnulldrop = new tbnulldrop();

// GRN items insert new row - won't save into DB
void makeItemRow(Component irows, String iname, String iatg, String isn, String iqty, String istat)
{
	k9 = "font-size:9px";
	nrw = new org.zkoss.zul.Row();
	nrw.setParent(irows);
	ngfun.gpMakeCheckbox(nrw,"","","");
	//ngfun.gpMakeTextbox(nrw,"",iname,k9,"98%",textboxnulldrop); // item-name
	ngfun.gpMakeLabel(nrw,"",iname,k9); // item-name using label

	if(istat.equals("DRAFT")) // draft GRN, insert textboxes
	{
		ngfun.gpMakeTextbox(nrw,"",iatg,k9,"95%",textboxnulldrop); // asset-tag
		ngfun.gpMakeTextbox(nrw,"",isn,k9,"95%",textboxnulldrop); // serial
		ngfun.gpMakeTextbox(nrw,"",iqty,k9,"95%",textboxnulldrop); // qty
	}
	else // else only labels
	{
		ngfun.gpMakeLabel(nrw,"",iatg,k9);
		ngfun.gpMakeLabel(nrw,"",isn,k9);
		ngfun.gpMakeLabel(nrw,"",iqty,k9);
	}
}

// general purpose remove items from list
// itype: 1=ticked, 2=all
void itemsRemovalfunc(int itype)
{
		try
		{
			jk = grn_rows.getChildren().toArray();
			for(i=0;i<jk.length;i++)
			{
				toremove = false;
				ki = jk[i].getChildren().toArray();
				if(ki[0].isChecked() && itype == 1)
					toremove = true;

				if(itype == 2) toremove = true;

				if(toremove) jk[i].setParent(null);
			}
		} catch (Exception e) {}	
}

class prdnsdblick implements org.zkoss.zk.ui.event.EventListener
{
	public void onEvent(Event event) throws UiException
	{
		selecProduct_pop.close();
		isel = event.getTarget();
		ifnd = lbhand.getListcellItemLabel(isel,0); // stock name
		//istk = lbhand.getListcellItemLabel(isel,1); // stock code
		try
		{
			jk = grn_rows.getChildren().toArray();
			for(i=0;i<jk.length;i++)
			{
				ki = jk[i].getChildren().toArray();
				if(ki[0].isChecked())
				{
					ki[1].setValue(ifnd); // refer to makeItemRow() for item column posi
					//ki[5].setValue(istk);
				}
			}
		//itemFunc("clrticks_b");
		} catch (Exception e) {}
	}
}
prodsearch_dclick = new prdnsdblick();

void searchProductName_FC(String sct)
{
	Object[] pnhds =
	{
		new listboxHeaderWidthObj("Product name",true,""),
		//new listboxHeaderWidthObj("STK",false,""),
	};

	sct = sct.trim();
	if(sct.equals("")) return;
	Listbox newlb = lbhand.makeVWListbox_Width(selprods_holder, pnhds, "prodname_lb", 3);
	sct = sct.replace(" ","%");
	sqlstm = "select top 50 name,masterid from mr008 where name like '%" + sct + "%' order by masterid desc";
	//r = sqlhand.rws_gpSqlGetRows(sqlstm);
	r = f30_gpSqlGetRows(sqlstm);
	if(r.size() == 0) return;
	newlb.setMold("paging"); newlb.setRows(20);
	ArrayList kabom = new ArrayList();
	String[] lbi = new String[1];
	for(d : r)
	{
		lbi[0] = d.get("name");
		//lbi[1] = d.get("masterid").toString();
		//ngfun.popuListitems_Data(kabom,flds,d);
		lbhand.insertListItems(newlb,lbi,"false","");
	}
	lbhand.setDoubleClick_ListItems(newlb, prodsearch_dclick);
}

// Split and insert scanned asset-tags and serials from textbox to grn-items list
void fillUp_scanned_assets()
{
	kk = main_scan_atgs.getValue().trim();
	if(kk.equals("")) return;
	atgs = kk.split("\n");

	kk2 = main_scan_serials.getValue().trim();
	snm = kk2.split("\n");

	if(atgs.length != snm.length) // imbalance asset-tags and serials
	{
		guihand.showMessageBox("Take note.. imbalance asset-tags and serials scanned.. but still insert");
	}

	for(i=0; i<atgs.length; i++)
	{
		tt = "";
		try { tt = snm[i]; } catch (Exception e) {}
		makeItemRow(grn_rows,"",atgs[i],tt,"1","DRAFT");
	}
}

// Really save grn-items into DB
void saveGRN_items(String igrn)
{
	try
	{
		itms = atgs = srls = qtys = "";

		jk = grn_rows.getChildren().toArray();
		for(i=0;i<jk.length;i++)
		{
			ki = jk[i].getChildren().toArray();

			ii = kiboo.replaceSingleQuotes( ki[1].getValue().trim().replaceAll("~"," ") );
			itms += ((ii.equals("")) ? "NONAME" : ii) + "~";

			ii = kiboo.replaceSingleQuotes( ki[2].getValue().trim().replaceAll("~"," ") );
			atgs += ((ii.equals("")) ? "NOTAG" : ii) + "~";

			ii = kiboo.replaceSingleQuotes( ki[3].getValue().trim().replaceAll("~"," ") );
			srls += ((ii.equals("")) ? "NOSN" : ii) + "~";

			ii = kiboo.replaceSingleQuotes( ki[4].getValue().trim().replaceAll("~"," ") );
			qtys += ((ii.equals("")) ? "NOQTY" : ii) + "~";
		}

		sqlstm = "update rw_grn set item_names='" + itms + "',asset_tags='" + atgs + "',serials='" + srls + "',qtys='" + qtys + "' where origid=" + igrn;
		sqlhand.gpSqlExecuter(sqlstm);
		guihand.showMessageBox("OK: GRN items saved..");

	} catch (Exception e) { guihand.showMessageBox("ERR: cannot save the GRN items.."); }
}

void showGRN_meta(String iwhat)
{
	r = getGRN_rec(iwhat);
	if(r == null) return;

	String[] fl = { "ourpo", "vendor", "vendor_do", "vendor_inv", "shipmentcode", "grn_remarks","origid" };
	Object[] jkl = { g_ourpo, g_vendor, g_vendor_do, g_vendor_inv, g_shipmentcode, g_grn_remarks, g_origid };
	ngfun.populateUI_Data(jkl,fl,r);

	fillDocumentsList(documents_holder,GRN_PREFIX,iwhat);

	// show 'em grn items
	itms = sqlhand.clobToString(r.get("item_names")).split("~");
	atgs = sqlhand.clobToString(r.get("asset_tags")).split("~");
	srls = sqlhand.clobToString(r.get("serials")).split("~");
	qtys = sqlhand.clobToString(r.get("qtys")).split("~");

	if(scanitems_holder.getFellowIfAny("grn_grid") != null) grn_grid.setParent(null);

	ngfun.checkMakeGrid(scanitems_colws, scanitems_collb, scanitems_holder, "grn_grid", "grn_rows", "", "", false);

	for(i=0;i<itms.length; i++)
	{
		try {
		makeItemRow(grn_rows,itms[i],atgs[i],srls[i],qtys[i],r.get("status"));
		} catch (Exception e) {}
	}

	grnmeta_holder.setVisible(true);
	grnitems_workarea.setVisible(true);

}

Object[] grnhds =
{
	new listboxHeaderWidthObj("GRN",true,"40px"),
	new listboxHeaderWidthObj("Date",true,"70px"),
	new listboxHeaderWidthObj("PO",true,"50px"),
	new listboxHeaderWidthObj("Stat",true,"60px"),
	new listboxHeaderWidthObj("User",true,"70px"),
	new listboxHeaderWidthObj("Commit",true,"70px"),
	new listboxHeaderWidthObj("Vendor",true,""),
	new listboxHeaderWidthObj("V.DO",true,"60px"),
	new listboxHeaderWidthObj("V.Inv",true,"60px"),
};
GRNSTAT_POS = 3;

class grnclicker implements org.zkoss.zk.ui.event.EventListener
{
	public void onEvent(Event event) throws UiException
	{
		isel = event.getReference();
		glob_sel_grn = lbhand.getListcellItemLabel(isel,0);
		glob_sel_stat = lbhand.getListcellItemLabel(isel,GRNSTAT_POS);
		showGRN_meta(glob_sel_grn);
	}
}
grnclik = new grnclicker();

// itype: 1=by search text, 2=by GRN id, 3=by asset-tag
void showGRN(int itype)
{
	last_showgrn_type = itype;
	sct = kiboo.replaceSingleQuotes(searhtxt_tb.getValue().trim());
	sdate = kiboo.getDateFromDatebox(startdate);
	edate = kiboo.getDateFromDatebox(enddate);
	jid = kiboo.replaceSingleQuotes(grnid_tb.getValue().trim());
	batg = kiboo.replaceSingleQuotes( assettag_by.getValue().trim() );

	Listbox newlb = lbhand.makeVWListbox_Width(grnheaders_holder, grnhds, "grnheader_lb", 3);
	sqlstm = "select origid,datecreated,ourpo,status,vendor,vendor_do,vendor_inv,username,commitdate from rw_grn ";
	switch(itype)
	{
		case 1 :
			sqlstm += "where datecreated between '" + sdate + " 00:00:00' and '" + edate + " 23:59:00' ";
			if(!sct.equals(""))
				sqlstm += " and (vendor like '%" + sct + "%' or vendor_do like '%" + sct + "%' or vendor_inv like '%" + sct + "% or ourpo like '%" + sct + "%' " +
				"or grn_remarks like '%" + sct + "%' or shipmentcode like '%" + sct + "%') ";
			break;
		case 2 : // by grn-id
			sqlstm += "where origid=" + jid;
			break;
		case 3 : // by asset-tag
			sqlstm += "where convert(nvarchar(max),asset_tags) like '%" + batg + "%' ";
			break;
	}
	sqlstm += " order by origid desc";

	rcs = sqlhand.gpSqlGetRows(sqlstm);
	if(rcs.size() == 0) return;
	newlb.setRows(20); newlb.setMold("paging");
	newlb.addEventListener("onSelect", grnclik);
	ArrayList kabom = new ArrayList();
	String[] fl = { "origid","datecreated","ourpo","status","username","commitdate","vendor","vendor_do","vendor_inv"};
	for(d : rcs)
	{
		ngfun.popuListitems_Data(kabom,fl,d);
		lbhand.insertListItems(newlb,kiboo.convertArrayListToStringArray(kabom),"false","");
		kabom.clear();
	}
}




