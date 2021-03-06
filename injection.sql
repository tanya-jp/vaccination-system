-- DROP PROCEDURE IF EXISTS db.injection;
CREATE PROCEDURE db.injection(
	in login_time varchar(64),
	in person_ID varchar(32),
	in vaccination_center_name varchar(32),
	in vial_serial varchar(32),
	out res char(64)
	)
begin
	set @vaccinatorID = "";
	set @nurseID = "";
	set @doses = 0;
	set @vialDoses = 0;
	set @brandName = "";
	set @branDoses = 0;
	set @vialUsedDoses = 0;
	set @lastBrandName = "";
	set @lastVial = "";

	select count(*) into @vialUsedDoses
	from `DB`.vial as v
	join `DB`.history as h 
	on h.vial_serial = v.serial_number
	where v.serial_number = vial_serial
	group by v.serial_number;
	
	IF (EXISTS (SELECT * FROM `DB`.login WHERE MD5(`DB`.login.login_time) = login_time)) then
		SELECT ID INTO @vaccinatorID FROM `DB`.login WHERE MD5(`DB`.login.login_time) = login_time;
		if (EXISTS (SELECT * FROM `DB`.nurse WHERE `DB`.nurse.ID = @vaccinatorID)) then 
			SELECT nurse_ID  into @nurseID FROM `DB`.nurse WHERE `DB`.nurse.ID = @personID;
			if (EXISTS (SELECT * FROM `DB`.system_info WHERE `DB`.system_info.ID = person_ID)) then 
				if (EXISTS (SELECT * FROM `DB`.health_center WHERE `DB`.health_center.name = vaccination_center_name)) then 
					if (EXISTS (SELECT * FROM `DB`.vial WHERE `DB`.vial.serial_number = vial_serial)) then 
						SELECT count(*) into @doses FROM `DB`.history  WHERE `DB`.history.person_ID = person_ID;
						SELECT name, dose into @brandName, @vialDoses FROM `DB`.vial  WHERE `DB`.vial.serial_number = vial_serial;
						SELECT dose into @branDoses FROM `DB`.brand  WHERE `DB`.brand.name = @brandName;
						SELECT `DB`.history.vial_serial into @lastVial FROM `DB`.history  WHERE `DB`.history.person_ID = person_ID;
						SELECT name into @lastBrandName FROM `DB`.vial  WHERE `DB`.vial.serial_number = @lastVial;
						if (@branDoses > @doses) then
							if(@vialUsedDoses < @vialDoses) then
								if(@lastBrandName = @brandName or @doses = 0) then
									INSERT INTO `DB`.history 
										values (person_ID, @nurseID, vaccination_center_name ,vial_serial, CURRENT_DATE(), 0);
									set res = "@Done!";
								else 
									set res = "Brand is differen!";
								end if;
							else 
								set res = "This vial is empty.";
							end if;
						else 
							set res = "This person is fully vaccinated!";
						end if;
					else
						set res =	"Invalid serial number.";
					end if;
				else
					set res =	"Invalid health center.";
				end if;
			else
				set res =	"Invalid ID number.";
			end if;
		else
			set res = "Vaccinator is not a nurse.";
		end if;
	else 
		set res = "This person is not logged in!";
	end if;
end