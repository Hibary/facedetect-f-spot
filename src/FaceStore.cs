// /home/andrzej/Projekty/soc/f-spot-devel/trunk/src/FaceStore.cs created with MonoDevelop
// User: andrzej at 20:24 2007-07-15
//
// To change standard headers go to Edit->Preferences->Coding->Standard Headers
//
// created on 2007-07-15 at 20:24

using Mono.Data.SqliteClient;
using System.Collections;
using System.IO;
using System;
using Banshee.Database;

public class Face : DbItem
{
	// The time is always in UTC.
	private Gdk.Rectangle rect;
	private uint tag_id;
	private uint photo_id;
	private Tag tag;
	
	public Gdk.Rectangle Rect {
		get { return rect; }
	}
	public uint TagId{
		get { 
			if(tag!=null)
				return tag.Id;
			else
				return tag_id;
				}
	}
	public uint PhotoId{
		get { return photo_id; }
	}

	public Tag Tag{
		get { return tag; }
	}
	
	public Face () : base (0) {
		rect = new Gdk.Rectangle(0,0,0,0);
		photo_id = 0;
		tag_id = 0;
		tag = null;
	}
	
	public Face (uint id, Gdk.Rectangle r) : base (id) {
		rect = r;
		
		photo_id = 0;
		tag_id = 0;
		tag = null;
	}
	
	public Face (Gdk.Rectangle r) : base (0) {
		
		rect = r;
		
		//id = 0;
		photo_id = 0;
		tag_id = 0;
				tag= null;
	}
	
	public Face (uint id, uint ph, uint tg, Gdk.Rectangle r) : base (id) {
		
		TagStore tag_store = FSpot.Core.Database.Tags;
		rect = r;
		photo_id = ph;
		tag_id = tg;
		
		tag = tag_store.GetTagById((int)tag_id);
	}
}

public class FaceStore : DbStore {
	
	public FaceStore (QueuedSqliteDatabase database, bool is_new) : base (database, false) {
		
		if (!is_new && Database.TableExists("faces"))
			return;
		Database.ExecuteNonQuery (
			"CREATE TABLE faces (                            " +
			"	id          INTEGER PRIMARY KEY NOT NULL,  " +
			"       photo_id     INTEGER NOT NULL,		   " +
		    "       tag_id       INTEGER NOT NULL,         " + 
	        "	    x            INTEGER NOT NULL,         " +
		    "       y            INTEGER NOT NULL,         " +
		    "       width        INTEGER NOT NULL,         " +
		    "       height       INTEGER NOT NULL          " +
			")");
	}
	public Face Create (Gdk.Rectangle r, uint photo_id, uint tag_id) {
		
		uint id = (uint) Database.Execute (new DbCommand ("INSERT INTO faces (photo_id, tag_id, x, y, width, height) VALUES (:photo_id, :tag_id, :x, :y, :width, :height)", 
		                                                  "photo_id", photo_id,
		                                                  "tag_id", tag_id,
		                                                  "x", r.X,
		                                                  "y", r.Y,
		                                                  "width", r.Width,
		                                                  "height", r.Height));
		
	
	Face face = new Face (id, r);
		AddToCache (face);
		return face;
	}
public override DbItem Get (uint id) {
		Face face = LookupInCache (id) as Face;
		if (face != null)
			return face;

		SqliteDataReader reader = Database.Query(new DbCommand ("SELECT * FROM faces WHERE id = :id", "id", id));

		if (reader.Read ()) {
			face = new Face (id, new Gdk.Rectangle((int)reader[3], (int)reader[4], (int)reader[5], (int)reader[6]));
			AddToCache (face);
		}

		return face;
	}
public Face [] GetFacesByPhotoId (uint photo_id) {
	    
	ArrayList list = new ArrayList ();	
	SqliteDataReader reader = Database.Query(new DbCommand ("SELECT * FROM faces WHERE photo_id = :id", "id", photo_id));
	Face face;
	while (reader.Read ()) {
			
		face = new Face (Convert.ToUInt32(reader[0]), 
			                 Convert.ToUInt32(reader[1]),
			                 Convert.ToUInt32(reader[2]),
			                 new Gdk.Rectangle((int)reader[3], (int)reader[4], (int)reader[5], (int)reader[6]));
		AddToCache (face);
		list.Add (face);
	}
	return (Face []) list.ToArray (typeof (Face));
	
}
	public override void Remove (DbItem item)
	{
		RemoveFromCache (item);
		Database.ExecuteNonQuery (new DbCommand ("DELETE FROM faces WHERE id = :id", "id", item.Id));
	}

	public override void Commit (DbItem item)
	{
		// Nothing to do here, since all the properties of a roll are immutable.
	}

}