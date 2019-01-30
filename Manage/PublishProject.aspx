<%@ Page Language="VB" MasterPageFile="~/Manage.master" AutoEventWireup="false" Inherits="Intelledox.Manage.PublishProject"
    CodeBehind="PublishProject.aspx.vb" %>

<%@ Register TagPrefix="Controls" Namespace="Intelledox.Manage" Assembly="Intelledox.Manage" %>
<%@ Register TagPrefix="control1" TagName="SkinSettings" Src="Controls\SkinSettings.ascx" %>
<%@ Register Src="Controls/ctlDate.ascx" TagName="ctlDate" TagPrefix="uc1" %>
<asp:Content ID="Content1" ContentPlaceHolderID="Content" runat="Server">
    <asp:ScriptManager ID="ScriptManager1" runat="server">
    </asp:ScriptManager>
    <script src="Scripts/jquery-3.1.1.min.js" type="text/javascript"></script>
    <script src="Scripts/PublishProject.js?v=10.0" type="text/javascript"></script>
    <script src="Scripts/TabPages.js?v=8.1" type="text/javascript"></script>
    <div id="contentinner" class="base1">
        <div class="toolbar">
            <asp:Button ID="btnSave" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Save %>" />
            <Controls:DeleteButton ID="btnDelete" runat="server" CssClass="toolbtn" CausesValidation="False"
                Text="<%$Resources:Strings, Remove %>"></Controls:DeleteButton>
            <span class="tooldiv" id="divSchedule" runat="server"></span>
            <asp:Button ID="btnSchedule" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Schedule %>" />
            <span class="tooldiv"></span>
            <asp:Button ID="btnBack" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Back %>"
                CausesValidation="false" />
        </div>
        <div class="body">
            <div class="msg" id="msg" runat="server" visible="false">
            </div>
            <asp:HiddenField ID="hidTabPage" runat="server" ClientIDMode="Static" />
            <asp:HiddenField ID="hidTab" runat="server" ClientIDMode="Static" />
            <input type="hidden" id="hidUpdateTemplate" name="hidUpdateTemplate" />
            <input type="hidden" id="hidUpdateLayout" name="hidUpdateLayout" />
            <table align="center" class="editsection" cellspacing="0" role="presentation" Style="width: 700px;"">
                <tr>
                    <td>
                        <span class="m">*</span><asp:Label ID="lblFolder" runat="server" Text="<%$Resources:Strings, Folder %>"></asp:Label>
                    </td>
                    <td>
                        <span id="txtFolder" class="LookupField">&nbsp;</span>
                        <input type="button" id="btnChangeFolder" value="..." onclick="popFolder()" />
                        <input type="hidden" id="hidFolderId" name="hidFolderId" />
                    </td>
                    <td>
                        <asp:CustomValidator ID="valFolderRequired" runat="server" ErrorMessage="" ClientValidationFunction="folderValidate"
                            Display="Dynamic" CssClass="wrn"></asp:CustomValidator>
                    </td>
                </tr>
                <tr>
                    <td valign="top">
                        <span class="m">*</span><asp:Label ID="lblTemplate" runat="server" Text="<%$Resources:Strings, Project %>"></asp:Label>
                    </td>
                    <td width="320px">
                        <span id="txtTemplate" class="LookupField">&nbsp;</span>
                        <input type="button" id="btnChangeTemplate" value="..." onclick="popTemplate(document.getElementById('hidProjectType').value, document.getElementById('hidLayoutId').value)" /><br />
                        <input type="hidden" id="hidTemplateId" name="hidTemplateId" />
                        <input type="hidden" id="hidLayoutId" name="hidLayoutId" />
                        <input type="hidden" id="hidProjectType" name="hidProjectType" />
                        <span style="float: right;"><em>
                        <%=Resources.Strings.Version%>:</em>
                            <asp:DropDownList ID="lstProjectVersion" runat="server" CssClass="fld">
                            </asp:DropDownList>
                        </span>
                    </td>
                    <td>
                        <asp:CustomValidator ID="valTemplate" runat="server" ErrorMessage="" 
                            Display="Dynamic" CssClass="wrn"></asp:CustomValidator>
                    </td>
                </tr>
                <tr id="rowLayout" runat="server">
                    <td valign="top">
                        <asp:Label ID="lblLayout" runat="server" Text="<%$Resources:Strings, LayoutOpt %>"></asp:Label>
                    </td>
                    <td width="320px">
                        <span id="txtLayout" class="LookupField">&nbsp;</span>
                        <input type="button" id="btnChangeLayout" value="..." onclick="popTemplate(2, document.getElementById('hidTemplateId').value)" /><br />
                        <span style="float: right;"><em>
                        <%=Resources.Strings.Version%>:</em>
                            <asp:DropDownList ID="lstLayoutVersion" runat="server" CssClass="fld">
                            </asp:DropDownList>
                        </span>
                    </td>
                    <td>
                        <asp:CustomValidator ID="valLayout" runat="server" ErrorMessage=""
                            Display="Dynamic" CssClass="wrn"></asp:CustomValidator>
                    </td>
                </tr>
                <tr id="rowId" runat="server">
                    <td valign="top">
                        <asp:Label ID="lblId" runat="server" Text="<%$ Resources:Strings, ID %>"></asp:Label>
                    </td>
                    <td width="320px">
                        <asp:Label ID="lblPublishGuid" runat="server"></asp:Label>
                    </td>
                    <td>
                    </td>
                </tr>
                <tr id="rowURL" runat="server">
                    <td valign="top">
    
                        <asp:Label ID="lblURL" runat="server" Text="<%$Resources:Strings, URL %>"></asp:Label>
                        </td>
                        <td width="320px">
                        <asp:Label ID="lblProduceURL" runat="server"></asp:Label>
                    </td>
                    <td>
                                            </td>
                </tr>
                <tr>
                    <td colspan="2">
                        <br />
                        <div id="tabOptions" style='width:110px' class="tabButton tabButtonActive" runat="server" clientIdMode="static"><a href="#void" onclick="pageChange('tabOptions', 'pageOptions');return false;"><%=Resources.Strings.PublishOptions%></a></div>
                        <div id="tabOutput" style='width:110px' class="tabButton" runat="server" clientIdMode="static"><a href="#void" onclick="pageChange('tabOutput', 'pageOutput');return false;"><%=Resources.Strings.Document%></a></div>
                        <div id="tabPresOutput" style='width:110px' class="tabButton" runat="server" clientIdMode="static"><a href="#void" onclick="pageChange('tabPresOutput', 'pagePresOutput');return false;"><%=Resources.Strings.Presentation%></a></div>
                        <div id="tabSpreadOutput" style='width:110px' class="tabButton" runat="server" clientIdMode="static"><a href="#void" onclick="pageChange('tabSpreadOutput', 'pageSpreadOutput');return false;"><%=Resources.Strings.Spreadsheet%></a></div>
                        <div id="tabMessages" style='width:110px' class="tabButton"><a href="#void" onclick="pageChange('tabMessages', 'pageMessages');return false;"><%=Resources.Strings.Messages%></a></div>
                        <div id="tabSkinSettings" style='width:110px' class="tabButton" runat="server" clientIdMode="static"><a href="#void" onclick="pageChange('tabSkinSettings', 'pageSkinSettings');return false;"><%=Intelledox.ViewModel.Core.Resources.Strings.SkinSettings%></a></div>
                        
                        <div id="pageOptions" class="tabPage" runat="server" clientidmode="static">
                            <table class="subfield" cellspacing="0" width="100%" role="presentation">
                                <tr>
                                    <th colspan="3">
                                        <%=Resources.Strings.PublicationSettings%>
                                    </th>
                                </tr>
                                <tr class="noBorder">
                                    <td colspan="3">
                                        <div id="nonDashboardOptions" runat="server">
                                            <div><asp:CheckBox ID="chkAllowPreview" runat="server" Text="<%$Resources:Strings, AllowPreview %>"
                                                Checked="false" /></div>
                                            <div><asp:CheckBox ID="chkAllowRestart" runat="server" Text="<%$Resources:Strings, AllowRestartWhenFinished %>"
                                                Checked="false" /></div>
                                            <div><asp:CheckBox ID="chkAllowSave" runat="server" Text="<%$Resources:Strings, AllowSave%>"
                                                Checked="true" /></div>
                                            <div><asp:CheckBox ID="chkAutoCreateInProgressForms" runat="server" Text="<%$Resources:Strings, AutoCreateInProgressForms%>"
                                                Checked="true" ToolTip="<%$Resources:Strings, AutoCreateInProgressFormsTooltip %>"/></div>
                                            <div><asp:CheckBox ID="chkLogPageTransition" runat="server" Text="<%$Resources:Strings, FormInteractionLog %>"
                                                Checked="false" /></div>
                                            <div><asp:CheckBox ID="chkEnforceValidation" runat="server" Text="<%$Resources:Strings, EnforceValidation %>"
                                                Checked="true" /></div>
                                            <div><asp:CheckBox ID="chkUpdateFields" runat="server" Text="<%$Resources:Strings, UpdateFields %>"
                                                Checked="true" /></div>
                                            <div><asp:CheckBox ID="chkHideNavigationPane" runat="server" Text="<%$Resources:Strings, HideNavigationPane %>"
                                                Checked="false" AutoPostBack="true" ToolTip="<%$Resources:Strings, HideNavigationPaneTooltip %>" /></div>
                                            <div><asp:CheckBox ID="chkShowFormActivity" runat="server" Text="<%$Resources:Strings, ShowFormActivity %>"
                                                Checked="true" ToolTip="<%$Resources:Strings, ShowFormActivityTooltip %>" /></div>
                                            <div><asp:CheckBox ID="chkMatchProjectVersion" runat="server" Text="<%$Resources:Strings, MatchProjectVersion %>"
                                                Checked="false" ToolTip="<%$Resources:Strings, MatchProjectVersionTooltip %>" /></div>
                                            <div><asp:CheckBox ID="chkOfflineDataSources" runat="server" Text="<%$Resources:Strings, AllowOfflineLaunch %>"
                                                Checked="false" /></div>
                                        </div>
                                        <div><asp:CheckBox ID="chkTroubleshooting" runat="server" Text="<%$Resources:Strings, TroubleshootingMode %>"
                                            Checked="false" AutoPostBack="true" ToolTip="<%$Resources:Strings, TroubleshootingModeTooltip %>" /></div>
                                    </td>
                                </tr>
                                
                                <tr id="trTroubleshootingModeOptions" runat="server" class="noBorder">
                                    <td width="20px">
                                    </td>
                                    <td colspan="2">
                                        <div><asp:CheckBox ID="chkShowVariables" runat="server" Text="<%$Resources:Strings, ShowVariables %>"
                                                Checked="true" /></div>
                                        <div><asp:CheckBox ID="chkShowDatasourceData" runat="server" Text="<%$Resources:Strings, ShowDatasourceData %>"
                                                Checked="true" /></div>
                                    </td>
                                </tr>
                                <tr class="noBorder">
                                    <td colspan="3">
                                        <div><asp:CheckBox ID="chkSetAsHome" runat="server" Text="<%$Resources:Strings, SetAsHomePage %>"
                                            Checked="false" /></div>
                                        <div><asp:CheckBox ID="chkAvailability" runat="server" Text="<%$Resources:Strings, RestrictAvailabilityDates %>"
                                            Checked="false" AutoPostBack="true" ToolTip="<%$Resources:Strings, AvailabilityDateTooltip %>" /></div>
                                        <asp:CustomValidator ID="valAvailability" runat="server" ErrorMessage="" Display="Dynamic"
                                            OnServerValidate="CheckAvailability" CssClass="wrn"></asp:CustomValidator>
                                    </td>
                                </tr>
                                <tr id="trFrom" runat="server" class="noBorder">
                                    <td width="20px">
                                    </td>
                                    <td>
                                        <asp:Label Text="<%$Resources:Strings, From %>" runat="server" ID="lblFrom"></asp:Label>
                                    </td>
                                    <td>
                                        <uc1:ctlDate ID="dteFrom" runat="server" />
                                    </td>
                                </tr>
                                <tr id="trUntil" runat="server" class="noBorder">
                                    <td width="20px">
                                    </td>
                                    <td>
                                        <asp:Label Text="<%$Resources:Strings, UntilString %>" runat="server" ID="lblUntil"></asp:Label>
                                    </td>
                                    <td>
                                        <uc1:ctlDate ID="dteUntil" runat="server" />
                                    </td>
                                </tr>
                            </table>
                        </div>
                        <div id="pageOutput" class="tabPage" runat="server" clientIdMode="static" style="display: none">
                            <table class="subfield" cellspacing="0" width="100%" role="presentation">
                                <tr>
                                    <th><%=Resources.Strings.Format%></th>
                                    <th width="1px" align="center"><%=Resources.Strings.Lock%></th>
                                </tr>
                                <tr>
                                    <td colspan="2">
                                        <asp:CustomValidator ID="valOutput" runat="server" ErrorMessage="" ClientValidationFunction="outputValidate"
                                            Display="Dynamic" CssClass="wrn"></asp:CustomValidator>
                                    </td>
                                </tr>
                                <tr>
                                    <td colspan="2">
                                        <div>
                                            <asp:CheckBox ID="chkDocx" runat="server" Text="<%$Resources:Strings, WordDocxDesc %>"
                                                ClientIDMode="Static" />
                                            <asp:CheckBox ID="chkLockDocx" runat="server" CssClass="floatRight" />
                                            <br />
                                            &nbsp;&nbsp;&nbsp;&nbsp;<asp:RadioButton ID="rdoDocx2007" runat="server" Text="2007"
                                                GroupName="DOCXFormat" ClientIDMode="Static" width="70px"/>
                                            <asp:RadioButton ID="rdoDocx2010" runat="server" Text="2010"
                                                GroupName="DOCXFormat" ClientIDMode="Static" />
                                        </div>
                                        <div>
                                            <asp:CheckBox ID="chkPdf" runat="server" Text="<%$Resources:Strings, PDFDesc %>"
                                                ClientIDMode="Static" />
                                            <asp:CheckBox ID="chkLockPdf" runat="server" CssClass="floatRight" ClientIDMode="Static" />
                                            <br />
                                            &nbsp;&nbsp;&nbsp;&nbsp;<asp:RadioButton ID="rdoPDF15" runat="server" Text="PDF1.5"
                                                GroupName="PDFFormat" ClientIDMode="Static" width="70px" />
                                            <asp:RadioButton ID="rdoPDFA" runat="server" Text="PDF/A-1b"
                                                GroupName="PDFFormat" ClientIDMode="Static" />
                                            <br />
                                            &nbsp;&nbsp;&nbsp;&nbsp;<asp:CheckBox ID="chkEmbedFonts" runat="server" Text="<%$Resources:Strings, EmbedFonts %>" ClientIDMode="Static" /><br />
                                            &nbsp;&nbsp;&nbsp;&nbsp;<asp:CheckBox ID="chkCreateOutline" runat="server" Text="<%$Resources:Strings, CreateOutline %>" ClientIDMode="Static" />
                                        </div>
                                        <div>
                                            <asp:CheckBox ID="chkDoc" runat="server" Text="<%$Resources:Strings, WordBinaryDesc %>" />
                                            <asp:CheckBox ID="chkLockDoc" runat="server" CssClass="floatRight" />
                                        </div>
                                        <div>
                                            <asp:CheckBox ID="chkRtf" runat="server" Text="<%$Resources:Strings, RtfDesc %>" />
                                        </div>
                                        <div>
                                            <asp:CheckBox ID="chkOdt" runat="server" Text="<%$Resources:Strings, OdtDesc %>" />
                                        </div>
                                        <div>
                                            <asp:CheckBox ID="chkXps" runat="server" Text="<%$Resources:Strings, XpsDesc %>" />
                                            <asp:CheckBox ID="chkLockXps" runat="server" CssClass="floatRight" />
                                        </div>
                                        <div>
                                            <asp:CheckBox ID="chkMht" runat="server" Text="<%$Resources:Strings, MhtDesc %>" />
                                        </div>
                                        <div>
                                            <asp:CheckBox ID="chkPs" runat="server" Text="<%$Resources:Strings, PsDesc %>" />
                                        </div>
                                        <input type="hidden" id="hidChks" value="<%=chkDoc.ClientID & "|" & chkDocx.ClientID & "|" & chkPdf.ClientID & "|" &
                                                                    chkRtf.ClientID & "|" & chkOdt.ClientID & "|" & chkXps.ClientID & "|" & chkMht.ClientID & "|" &
                                                                    chkPptx.ClientID & "|" & chkPresPdf.ClientID & "|" & chkOdp.ClientID & "|" & chkPresXps.ClientID & "|" & chkPs.ClientID%>" />
                                        <input type="hidden" id="hidLockChks" value="<%=chkLockDocx.ClientID & "|" & chkLockDoc.ClientID & "|" &
                                                        chkLockPdf.ClientID & "|" & chkLockXps.ClientID & "|" & chkLockPptx.ClientID & "|" & chkLockPresXps.ClientId %>" />
                                    </td>
                                </tr>
                            </table>
                        </div>

                        <div id="pagePresOutput" class="tabPage" runat="server" clientIdMode="static" style="display:none">
                            <table class="subfield" cellspacing="0" width="100%" role="presentation">
                                <tr>
                                    <th><%=Resources.Strings.Format%></th>
                                    <th width="1px" align="center"><%=Resources.Strings.Lock%></th>
                                </tr>
                                <tr>
                                    <td colspan="2"><asp:CustomValidator ID="valPresOutout" runat="server" ErrorMessage="" ClientValidationFunction="outputValidate" Display="Dynamic" CssClass="wrn"></asp:CustomValidator></td>
                                </tr>
                                <tr>
                                    <td colspan="2">
                                        <div>
                                            <asp:CheckBox ID="chkPptx" runat="server" Text="<%$Resources:Strings, PowerPointPptxDesc %>" ClientIDMode="Static" />
                                            <asp:CheckBox ID="chkLockPptx" runat="server" CssClass="floatRight" />
                                        </div>
                                        <div>
                                            <asp:CheckBox ID="chkPresPdf" runat="server" Text="<%$Resources:Strings, PDFDesc %>" ClientIDMode="Static" />
                                            <asp:CheckBox ID="chkLockPresPdf" runat="server" CssClass="floatRight" ClientIDMode="Static" />
                                            <br />&nbsp;&nbsp;&nbsp;&nbsp;<asp:RadioButton ID="rdoPresPDF15" runat="server" Text="PDF1.5" GroupName="PresPDFFormat" ClientIDMode="Static" Width="70px" />
                                            <asp:RadioButton ID="rdoPresPDFA" runat="server" Text="PDF/A-1b" GroupName="PresPDFFormat" ClientIDMode="Static" />
                                        </div>
                                        <div>
                                            <asp:CheckBox ID="chkOdp" runat="server" Text="<%$Resources:Strings, OdpDesc %>" />
                                        </div>
                                        <div>
                                            <asp:CheckBox ID="chkPresXps" runat="server" Text="<%$Resources:Strings, XpsDesc %>" />
                                            <asp:CheckBox ID="chkLockPresXps" runat="server" CssClass="floatRight" />
                                        </div>
                                    </td>
                                </tr>
                            </table>
                        </div>
                        <div id="pageSpreadOutput" class="tabPage" runat="server" clientIdMode="static" style="display:none">
                            <table class="subfield" cellspacing="0" width="100%" role="presentation">
                                <tr>
                                    <th><%=Resources.Strings.Format%></th>
                                    <th width="1px" align="center"><%=Resources.Strings.Lock%></th>
                                </tr>
                                <tr>
                                    <td colspan="2"><asp:CustomValidator ID="valSpreadOutput" runat="server" ErrorMessage="" ClientValidationFunction="outputValidate" Display="Dynamic" CssClass="wrn"></asp:CustomValidator></td>
                                </tr>
                                <tr>
                                    <td colspan="2">
                                        <div>
                                            <asp:CheckBox ID="chkXlsx" runat="server" Text="<%$Resources:Strings, XlsxDesc %>" ClientIDMode="Static" />
                                            <asp:CheckBox ID="chkLockXlsx" runat="server" CssClass="floatRight" />
                                        </div>
                                        <div>
                                            <asp:CheckBox ID="chkXls" runat="server" Text="<%$Resources:Strings, XlsDesc %>" ClientIDMode="Static" />
                                            <asp:CheckBox ID="chkLockXls" runat="server" CssClass="floatRight" />
                                        </div>
                                        <div>
                                            <asp:CheckBox ID="chkSpreadPdf" runat="server" Text="<%$Resources:Strings, PDFDesc %>" ClientIDMode="Static" />
                                            <asp:CheckBox ID="chkLockSpreadPdf" runat="server" CssClass="floatRight" ClientIDMode="Static" />
                                            <br />&nbsp;&nbsp;&nbsp;&nbsp;<asp:RadioButton ID="rdoSpreadPDF15" runat="server" Text="PDF1.5" GroupName="SpreadPDFFormat" ClientIDMode="Static" Width="70px" />
                                            <asp:RadioButton ID="rdoSpreadPDFA" runat="server" Text="PDF/A-1b" GroupName="SpreadPDFFormat" ClientIDMode="Static" />
                                        </div>
                                        <div>
                                            <asp:CheckBox ID="chkSpreadXps" runat="server" Text="<%$Resources:Strings, XpsDesc %>" />
                                            <asp:CheckBox ID="chkLockSpreadXps" runat="server" CssClass="floatRight" />
                                        </div>
                                        <div>
                                            <asp:CheckBox ID="chkOds" runat="server" Text="<%$Resources:Strings, OdsDesc %>" />
                                        </div>
                                    </td>
                                </tr>
                            </table>
                        </div>
                        <div id="pageMessages" class="tabPage" style="display: none">
                            <table class="editsection" cellspacing="0" width="100%" role="presentation">
                                <tr>
                                    <th colspan="2">
                                        <%=Resources.Strings.CustomisableTextAndMessages%>
                                    </th>
                                </tr>
                                <tr>
                                    <td valign="top">
                                        <asp:Label ID="lblHelpText" runat="server" Text="<%$Resources:Strings, HelpText %>"
                                            AssociatedControlID="txtHelpText"></asp:Label>
                                    </td>
                                    <td>
                                        <asp:TextBox ID="txtHelpText" runat="server" TextMode="MultiLine" Columns="40" Rows="10"
                                            Width="100%"></asp:TextBox>
                                    </td>
                                </tr>
                                <tr>
                                    <td valign="top" width="145px">
                                        <asp:Label ID="lblFinishText" runat="server" Text="<%$Resources:Strings, WizardFinishPage %>"
                                            AssociatedControlID="txtFinishText"></asp:Label>
                                    </td>
                                    <td>
                                        <asp:TextBox ID="txtFinishText" runat="server" TextMode="MultiLine" Columns="40"
                                            Rows="10" Width="100%"></asp:TextBox>
                                    </td>
                                </tr>
                                <tr>
                                    <td valign="top" width="145px">
                                        <asp:Label ID="lblPostGenerateText" runat="server" Text="<%$Resources:Strings, PostGenerationInstructions %>"
                                            AssociatedControlID="txtPostGenerateText"></asp:Label>
                                    </td>
                                    <td>
                                        <asp:TextBox ID="txtPostGenerateText" runat="server" TextMode="MultiLine" Columns="40"
                                            Rows="10" Width="100%"></asp:TextBox>
                                    </td>
                                </tr>
                            </table>
                        </div>
                        <div id="pageSkinSettings" class="tabPage" style="display: none" runat="server" clientidmode="static">
                            <control1:SkinSettings ID="projectSkin" runat="server" />
                        </div>
                    </td>
                </tr>
            </table>
            <br />
            <br />
        </div>
    </div>
    <script type="text/javascript">
        chkDocx_OnClick();
        chkPdf_OnClick();
        chkPresPdf_OnClick();
        chkSpreadPdf_OnClick();
        rdoPDFA_OnClick();
        rdoPresPDFA_OnClick();
        rdoSpreadPDFA_OnClick();
    </script>
</asp:Content>
