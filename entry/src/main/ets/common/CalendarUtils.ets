import { abilityAccessCtrl, common, PermissionRequestResult, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { calendarManager } from '@kit.CalendarKit';
import { AppUtil, DateUtil, LogUtil, PermissionUtil, ToastUtil } from '@pura/harmony-utils';
import { data } from '@kit.TelephonyKit';

export default class CalendarUtils {
  static shared: CalendarUtils = new CalendarUtils()
  calendarMgr: calendarManager.CalendarManager | null = null;
  calendarAccount: calendarManager.CalendarAccount = {
    name: 'MyCalendar',
    type: calendarManager.CalendarType.LOCAL,
    displayName: 'J博士'
  };
  config: calendarManager.CalendarConfig = {
    enableReminder: true,
    color: '#0959F7'
  };
  calendar: calendarManager.Calendar | undefined = undefined;

  setup(mContext: common.UIAbilityContext) {
    const permissions: Permissions[] = ['ohos.permission.READ_CALENDAR', 'ohos.permission.WRITE_CALENDAR'];
    let atManager = abilityAccessCtrl.createAtManager();
    atManager.requestPermissionsFromUser(mContext, permissions).then((result: PermissionRequestResult) => {
      LogUtil.info(`get Permission success, result: ${JSON.stringify(result)}`);
      CalendarUtils.shared.calendarMgr = calendarManager.getCalendarManager(mContext);
      this.creatAccount();
    }).catch((error: BusinessError) => {
      LogUtil.error(`get Permission error, error. Code: ${error.code}, message: ${error.message}`);
    })
  }

  creatAccount() {
    // 创建日历账户
    this.calendarMgr?.createCalendar(this.calendarAccount).then((data: calendarManager.Calendar) => {
      console.info(`Succeeded in creating calendar data->${JSON.stringify(data)}`);
      this.calendar = data;
      this.calendar.setConfig(this.config).then(() => {
        LogUtil.info(`Succeeded in setting config, data->${JSON.stringify(this.config)}`);
      }).catch((err: BusinessError) => {
        LogUtil.error(`Failed to set config. Code: ${err.code}, message: ${err.message}`);
      });
    }).catch((error: BusinessError) => {
      LogUtil.error(`Failed to create creatAccount. Code: ${error.code}, message: ${error.message}`);
    });
  }

  async checkPermission() {
    const p1 = await PermissionUtil.checkPermissions('ohos.permission.READ_CALENDAR')
    const p2 = await PermissionUtil.checkPermissions('ohos.permission.WRITE_CALENDAR')
    if (p1 && p2 && this.calendar != undefined) {
      return true
    }
    return false
  }

  async creatCalendar(title: string, startTime: string, endTime: string, alarmTime: number) {
    const result = await this.checkPermission()
    if (!result) {
      this.setup(AppUtil.getContext())
      return
    }
    const startDate = DateUtil.getFormatDate(startTime).getTime();
    const endDate = DateUtil.getFormatDate(endTime).getTime();
    let alarmTimeArray: number[] = [];
    if (alarmTime >= 0) {
      alarmTimeArray.push(alarmTime / 60)
    }
    const event: calendarManager.Event = {
      title: title,
      type: calendarManager.EventType.NORMAL,
      startTime: startDate,
      endTime: endDate,
      reminderTime: alarmTimeArray
      // service: {
      //   type: calendarManager.ServiceType.TRIP,
      //   uri: 'jbs://',
      //   description: '查看'
      // }
    };
    const eventId = await this.calendar?.addEvent(event)
    return String(eventId)
  }

  async updateCalendar(eventId: string, title: string, startTime: string, endTime: string, alarmTime: number) {
    const result = await this.checkPermission()
    if (!result) {
      this.setup(AppUtil.getContext())
      return
    }
    const startDate = DateUtil.getFormatDate(startTime).getTime();
    const endDate = DateUtil.getFormatDate(endTime).getTime();
    let alarmTimeArray: number[] = [];
    if (alarmTime >= 0) {
      alarmTimeArray.push(alarmTime / 60)
    }
    const updateEvent: calendarManager.Event = {
      id: Number(eventId),
      title: title,
      type: calendarManager.EventType.NORMAL,
      startTime: startDate,
      endTime: endDate,
      reminderTime: alarmTimeArray
    };
    await this.calendar?.updateEvent(updateEvent)
    return String(eventId)
  }

  async deleteCalendar(eventId: string) {
    const result = await this.checkPermission()
    if (!result) {
      this.setup(AppUtil.getContext())
      return
    }
    await this.calendar?.deleteEvent(Number(eventId))
  }

  async getCalendar(eventId: string) {
    const filterId = calendarManager.EventFilter.filterById([Number(eventId)]);
    const datas = await this.calendar?.getEvents(filterId) ?? []
    const data = datas.pop()
    if (data) {
      let reminderTime = data.reminderTime?.pop()
      if (reminderTime) {
        reminderTime = reminderTime * 60
      }
      return {
        eventId: data.id?.toString(),
        title: data.title,
        startTime: DateUtil.getFormatDateStr(data.startTime),
        endTime: DateUtil.getFormatDateStr(data.endTime),
        alarmTime: reminderTime?.toString()
      } as EventObj
    }
    return undefined
  }
}

export interface EventObj {
  eventId?: string
  title?: string
  startTime?: string
  endTime?: string
  alarmTime?: string
}